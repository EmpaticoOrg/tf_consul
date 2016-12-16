data "aws_vpc" "environment" {
  id = "${var.vpc_id}"
}

data "aws_route53_zone" "domain" {
  name = "${var.domain}."
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
    region = "${var.region}"
  }
}

resource "aws_launch_configuration" "consul" {
  image_id        = "${lookup(var.ami, var.region)}"
  instance_type   = "${var.instance_type}"
  key_name        = "${var.key_name}"
  security_groups = ["${aws_security_group.consul.id}"]

  user_data = "${template_file.consul_userdata.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "consul" {
  name                 = "consul - ${aws_launch_configuration.consul.name}"
  launch_configuration = "${aws_launch_configuration.consul.name}"
  desired_capacity     = 5
  min_size             = 3
  max_size             = 5
  min_elb_capacity     = 3
  load_balancers       = ["${aws_elb.consul.id}"]

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
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

  // These allow the DNS and HTTP API client interfaces to be queried. Here be dragons.
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
}

resource "aws_security_group" "consul_inbound_sg" {
  name        = "${var.environment}-${var.app}-${var.role}-inbound"
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
    Name = "${var.environment}-${var.app}-${var.role}-inbound-sg"
  }
}
