data "aws_vpc" "environment" {
  id = "${var.vpc_id}"
}

data "aws_security_group" "core" {
  filter {
    name   = "tag:Name"
    values = ["core-to-${var.environment}-sg"]
  }
}

data "aws_route53_zone" "domain" {
  name = "${var.domain}."
}

data "aws_ami" "base_ami" {
  filter {
    name   = "tag:Role"
    values = ["base"]
  }

  most_recent = true
}

resource "aws_elb" "consul" {
  name            = "${var.environment}-${var.role}-elb"
  subnets         = ["${var.public_subnet_id}"]
  security_groups = ["${aws_security_group.consul_inbound_sg.id}"]

  listener {
    instance_port     = 8500
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8500/v1/status/leader"
    interval            = 30
  }

  access_logs {
    bucket = "empatico-elb-logs"
    bucket_prefix = "${var.app}"
    enabled = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "consul" {
  zone_id = "${data.aws_route53_zone.domain.zone_id}"
  name    = "consul.${data.aws_route53_zone.domain.name}"
  type    = "A"

  alias {
    name                   = "${aws_elb.consul.dns_name}"
    zone_id                = "${aws_elb.consul.zone_id}"
    evaluate_target_health = true
  }
}

data "template_file" "consul" {
  template = "${file("${path.module}/files/initialize.sh")}"

  vars {
    region         = "${var.region}"
    environment    = "${var.environment}"
    encryption_key = "${var.encryption_key}"
    mastertoken    = "${var.mastertoken}"
  }
}

resource "aws_launch_configuration" "consul" {
  name_prefix   = "${var.environment}-${var.role}-${var.app}-"
  image_id      = "${data.aws_ami.base_ami.id}"
  instance_type = "${var.instance_type}"
  key_name      = "${var.key_name}"

  security_groups = ["${aws_security_group.consul.id}",
    "${data.aws_security_group.core.id}",
  ]

  associate_public_ip_address = false
  user_data                   = "${data.template_file.consul.rendered}"
  iam_instance_profile        = "${aws_iam_instance_profile.consul.name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_instance_profile" "consul" {
  name_prefix = "consul"
  roles       = ["ConsulInit"]
}

resource "aws_autoscaling_group" "consul" {
  name                      = "${aws_launch_configuration.consul.name}-asg"
  launch_configuration      = "${aws_launch_configuration.consul.name}"
  desired_capacity          = 5
  min_size                  = 3
  max_size                  = 5
  min_elb_capacity          = 3
  load_balancers            = ["${aws_elb.consul.id}"]
  vpc_zone_identifier       = ["${var.public_subnet_id}"]

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.environment}-${var.role}-${var.app}"
    propagate_at_launch = "true"
  }

  tag {
    key                 = "Role"
    value               = "${var.role}"
    propagate_at_launch = "true"
  }

  tag {
    key                 = "Flag"
    value               = "consul"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "consul" {
  name        = "${var.environment}-${var.role}-${var.app}-internal"
  description = "Consul internal traffic + maintenance."
  vpc_id      = "${data.aws_vpc.environment.id}"

  // These are for internal traffic
  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "udp"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.environment}-${var.role}-${var.app}-internal-sg"
  }
}

resource "aws_security_group" "consul_inbound_sg" {
  name        = "${var.environment}-${var.role}-${var.app}-inbound"
  description = "Allow HTTP from Anywhere"
  vpc_id      = "${data.aws_vpc.environment.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.environment}-${var.role}-${var.app}-inbound-sg"
  }
}
