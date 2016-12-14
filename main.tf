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
    target              = "HTTP:8500/"
    interval            = 30
  }

  instances = ["${aws_instance.server.*.id}"]
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

resource "aws_instance" "server" {
  ami           = "${lookup(var.ami, "${var.region}-${var.platform}")}"
  instance_type = "${var.instance_type}"
  key_name      = "${var.key_name}"
  subnet_id     = "${var.public_subnet_id}"
  count         = "${var.servers}"

  vpc_security_group_ids = [
    "${aws_security_group.consul.id}",
  ]

  connection {
    bastion_host = "${var.bastion_host}"
    host         = "${self.private_ip}"
    user         = "${lookup(var.user, var.platform)}"
    private_key  = "${file("${var.key_path}")}"
  }

  #Instance tags
  tags {
    Name       = "${var.environment}-${var.role}-server-${count.index}"
    ConsulRole = "Server"
    Project    = "${var.app}"
    Stages     = "${var.environment}"
    Roles      = "${var.role}"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/${lookup(var.service_conf, var.platform)}"
    destination = "/tmp/${lookup(var.service_conf_dest, var.platform)}"
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${var.servers} > /tmp/consul-server-count",
      "echo ${aws_instance.server.0.private_dns} > /tmp/consul-server-addr",
      "echo ConsulServer${count.index} > /tmp/consul-node-name",
      "echo ${var.encryption_key} > /tmp/consul-encryption-key",
      "echo ${var.environment} > /tmp/consul-datacenter",
      "echo ${var.mastertoken} > /tmp/consul-mastertoken",
    ]
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/install.sh",
      "${path.module}/scripts/server_config.sh",
      "${path.module}/scripts/service.sh",
      "${path.module}/scripts/ip_tables.sh",
    ]
  }
}

resource "aws_instance" "client" {
  ami           = "${lookup(var.ami, "${var.region}-${var.platform}")}"
  instance_type = "${var.instance_type}"
  key_name      = "${var.key_name}"
  subnet_id     = "${var.public_subnet_id}"
  count         = "${var.clients}"

  vpc_security_group_ids = [
    "${aws_security_group.consul.id}",
  ]

  connection {
    bastion_host = "${var.bastion_host}"
    host         = "${self.private_ip}"
    user         = "${lookup(var.user, var.platform)}"
    private_key  = "${file("${var.key_path}")}"
  }

  #Instance tags
  tags {
    Name       = "${var.environment}-${var.role}-client-${count.index}"
    ConsulRole = "Client"
    Project    = "${var.app}"
    Stages     = "${var.environment}"
    Roles      = "${var.role}"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/${lookup(var.service_conf, var.platform)}"
    destination = "/tmp/${lookup(var.service_conf_dest, var.platform)}"
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${aws_instance.server.0.private_dns} > /tmp/consul-server-addr",
      "echo ConsulClient${count.index} > /tmp/consul-node-name",
      "echo ${var.encryption_key} > /tmp/consul-encryption-key",
      "echo ${var.environment} > /tmp/consul-datacenter",
    ]
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/install.sh",
      "${path.module}/scripts/client_config.sh",
      "${path.module}/scripts/service.sh",
      "${path.module}/scripts/ip_tables.sh",
    ]
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
