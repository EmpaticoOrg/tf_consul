resource "aws_instance" "server" {
  ami             = "${lookup(var.ami, "${var.region}-${var.platform}")}"
  instance_type   = "${var.instance_type}"
  key_name        = "${var.key_name}"
  count           = "${var.servers}"
  security_groups = ["${aws_security_group.consul.name}"]

  connection {
    user        = "${lookup(var.user, var.platform)}"
    private_key = "${file("${var.key_path}")}"
  }

  #Instance tags
  tags {
    Name       = "${var.tagName}${count.index}"
    ConsulRole = "Server"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/${lookup(var.service_conf, var.platform)}"
    destination = "/tmp/${lookup(var.service_conf_dest, var.platform)}"
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${var.servers} > /tmp/consul-server-count",
      "echo ${aws_instance.server.0.private_dns} > /tmp/consul-server-addr",
      "echo Consul${count.index} > /tmp/consul-node-name",
      "echo ${var.encryption_key} > /tmp/consul-encryption-key",
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
  ami             = "${lookup(var.ami, "${var.region}-${var.platform}")}"
  instance_type   = "${var.instance_type}"
  key_name        = "${var.key_name}"
  count           = "${var.clients}"
  security_groups = ["${aws_security_group.consul.name}"]

  connection {
    user        = "${lookup(var.user, var.platform)}"
    private_key = "${file("${var.key_path}")}"
  }

  #Instance tags
  tags {
    Name       = "${var.tagName}Client${count.index}"
    ConsulRole = "Client"
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
  name        = "consul_${var.platform}"
  description = "Consul internal traffic + maintenance."

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
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8600
    to_port     = 8600
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // These are for maintenance
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // This is for outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
