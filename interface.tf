variable "environment" {
  description = "The name of our environment, i.e. development."
}

variable "mastertoken" {
  description = "The Consul master token"
}

variable "vpc_id" {
  description = "The VPC ID to launch in"
}

variable "public_subnet_id" {
  default     = ""
  description = "The public subnet to populate."
}

variable "bastion_host" {
  description = "The bastion host to provision through."
}

variable "ami" {
  description = "AWS AMI Id, if you change, make sure it is compatible with instance type, not all AMIs allow all instance types "

  default = {
    us-east-1      = "ami-da6168cd"
    us-west-1      = "ami-08490c68"
    us-west-2      = "ami-d06a90b0"
    eu-west-1      = "ami-0ae77879"
    eu-central-1   = "ami-79f51c16"
    ap-northeast-1 = "ami-b601ead7"
    ap-southeast-1 = "ami-e7a67584"
    ap-southeast-2 = "ami-61e3ca02"
  }
}

variable "key_name" {
  description = "SSH key name in your AWS account for AWS instances."
}

variable "key_path" {
  description = "Path to the private key specified by key_name."
}

variable "region" {
  default     = "us-east-1"
  description = "The region of AWS, for AMI lookups."
}

variable "servers" {
  default     = "3"
  description = "The number of Consul servers to launch."
}

variable "clients" {
  default     = "0"
  description = "The number of Consul clients to launch. Defaults to none."
}

variable "instance_type" {
  default     = "t2.micro"
  description = "AWS Instance type, if you change, make sure it is compatible with AMI, not all AMIs allow all instance types."
}

variable "app" {
  default     = "consul"
  description = "Name of application"
}

variable "role" {
  default     = "consul"
  description = "Role of servers"
}

variable "domain" {
  description = "Domain for Consul server"
}

variable "encryption_key" {
  description = "Encryption key. 16-bytes & Base64-encoded. Best generated with the consul keygen command."
}

output "consul_primary_server_address" {
  value = "${aws_instance.server.0.public_dns}"
}

output "consul_server_addresses" {
  value = ["${aws_instance.server.*.public_dns}"]
}

output "consul_client_addresses" {
  value = ["${aws_instance.client.*.public_dns}"]
}
