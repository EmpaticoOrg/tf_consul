output "consul_primary_server_address" {
  value = "${aws_instance.server.0.public_dns}"
}

output "consul_server_addresses" {
  value = ["${aws_instance.server.*.public_dns}"]
}

output "consul_client_addresses" {
  value = ["${aws_instance.client.*.public_dns}"]
}
