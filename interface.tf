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

variable "key_name" {
  description = "SSH key name in your AWS account for AWS instances."
}

variable "region" {
  default     = "us-east-1"
  description = "The region of AWS, for AMI lookups."
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
  default     = "discovery"
  description = "Role of servers"
}

variable "domain" {
  description = "Domain for Consul server"
}

variable "encryption_key" {
  description = "Encryption key. 16-bytes & Base64-encoded. Best generated with the consul keygen command."
}
