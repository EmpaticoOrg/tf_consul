variable "environment" {
  description = "The name of our environment, i.e. development."
}

variable "datacenter" {
  description = "The Consul data center"
}

variable "mastertoken" {
  description = "The Consul master token"
}

variable "vpc_id" {
  description = "The VPC ID to launch in"
}

variable "public_subnet_ids" {
  default     = []
  description = "The list of public subnets to populate."
}

variable "bastion_host" {
  description = "The bastion host to provision through."
}

variable "platform" {
  default     = "ubuntu"
  description = "The OS Platform"
}

variable "user" {
  default = {
    ubuntu  = "ubuntu"
    rhel6   = "ec2-user"
    centos6 = "centos"
    centos7 = "centos"
    rhel7   = "ec2-user"
  }
}

variable "ami" {
  description = "AWS AMI Id, if you change, make sure it is compatible with instance type, not all AMIs allow all instance types "

  default = {
    us-east-1-ubuntu      = "ami-f652979b"
    us-west-1-ubuntu      = "ami-08490c68"
    us-west-2-ubuntu      = "ami-d06a90b0"
    eu-west-1-ubuntu      = "ami-0ae77879"
    eu-central-1-ubuntu   = "ami-79f51c16"
    ap-northeast-1-ubuntu = "ami-b601ead7"
    ap-southeast-1-ubuntu = "ami-e7a67584"
    ap-southeast-2-ubuntu = "ami-61e3ca02"
    us-east-1-rhel6       = "ami-0d28fe66"
    us-west-2-rhel6       = "ami-3d3c0a0d"
    us-east-1-centos6     = "ami-57cd8732"
    us-west-2-centos6     = "ami-1255b321"
    us-east-1-rhel7       = "ami-2051294a"
    us-west-2-rhel7       = "ami-775e4f16"
    us-east-1-centos7     = "ami-6d1c2007"
    us-west-1-centos7     = "ami-af4333cf"
  }
}

variable "service_conf" {
  default = {
    ubuntu  = "ubuntu_consul.service"
    rhel6   = "rhel_upstart.conf"
    centos6 = "rhel_upstart.conf"
    centos7 = "rhel_consul.service"
    rhel7   = "rhel_consul.service"
  }
}

variable "service_conf_dest" {
  default = {
    ubuntu  = "consul.service"
    rhel6   = "upstart.conf"
    centos6 = "upstart.conf"
    centos7 = "consul.service"
    rhel7   = "consul.service"
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
