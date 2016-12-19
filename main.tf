data "aws_vpc" "environment" {
  id = "${var.vpc_id}"
}

data "aws_security_group" "prometheus" {
  filter {
    name   = "tag:Name"
    values = ["${var.environment}-prometheus-sg"]
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
  name            = "${var.environment}-consul-elb"
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
  template = "${file("${path.module}/scripts/initialize.sh")}"

  vars {
    region         = "${var.region}"
    environment    = "${var.environment}"
    encryption_key = "${var.encryption_key}"
    mastertoken    = "${var.mastertoken}"
  }
}

resource "aws_launch_configuration" "consul" {
  name_prefix   = "${var.environment}-${var.app}-${var.role}-"
  image_id      = "${data.aws_ami.base_ami.id}"
  instance_type = "${var.instance_type}"
  key_name      = "${var.key_name}"

  security_groups = ["${aws_security_group.consul.id}",
    "${data.aws_security_group.prometheus.id}",
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
  name                 = "${aws_launch_configuration.consul.name}-asg"
  launch_configuration = "${aws_launch_configuration.consul.name}"
  desired_capacity     = 5
  min_size             = 3
  max_size             = 5
  min_elb_capacity     = 3
  load_balancers       = ["${aws_elb.consul.id}"]
  vpc_zone_identifier  = ["${var.public_subnet_id}"]

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.environment}-${var.app}-server"
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
  name        = "${var.environment}-${var.app}-internal"
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

  ingress {
    from_port   = 8300
    to_port     = 8300
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_vpc.environment.cidr_block}"]
  }

  ingress {
    from_port   = 8301
    to_port     = 8301
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_vpc.environment.cidr_block}"]
  }

  ingress {
    from_port   = 8301
    to_port     = 8301
    protocol    = "udp"
    cidr_blocks = ["${data.aws_vpc.environment.cidr_block}"]
  }

  ingress {
    from_port   = 8302
    to_port     = 8302
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_vpc.environment.cidr_block}"]
  }

  ingress {
    from_port   = 8302
    to_port     = 8302
    protocol    = "udp"
    cidr_blocks = ["${data.aws_vpc.environment.cidr_block}"]
  }

  ingress {
    from_port   = 8500
    to_port     = 8500
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_vpc.environment.cidr_block}"]
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["${data.aws_vpc.environment.cidr_block}"]
  }

  // These are for maintenance
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_vpc.environment.cidr_block}"]
  }

  // This is for outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.environment}-${var.app}-internal-sg"
  }
}

resource "aws_security_group" "consul_inbound_sg" {
  name        = "${var.environment}-${var.app}-inbound"
  description = "Allow HTTP from Anywhere"
  vpc_id      = "${data.aws_vpc.environment.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.environment}-${var.app}-inbound-sg"
  }
}
