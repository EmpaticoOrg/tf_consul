# Empatico Consul Terraform module

Terraform Consul Module. Can create both server and client agents.

## Security

**Warning** - Enables encryption for the Gossip protocol and turns on ACLs with a single master ACL token. Secures the cluster from access except via the bastion host for SSH. Opens FW rule for HTTP and DNS interfaces but none of the interfaces are bound to an external IP by default. You could update that via the configuration file in the `scripts` directory. This may or may not be a good idea.

## Usage

```hcl
module "consul" {
  source            = "github.com/EmpaticoOrg/tf_consul"
  environment       = "${var.environment}"
  vpc_id            = "${module.vpc.vpc_id}"
  public_subnet_id  = "${module.vpc.public_subnet_id}"
  role              = "${var.role}"
  app               = "${var.app}"
  region            = "${var.region}"
  key_name          = "${var.key_name}"
  datacenter        = "${var.environment}"
  encryption_key    = "${var.encryption_key}"
  mastertoken       = "${var.mastertoken}"
  domain            = "${var.domain}"
}
```

Assumes you're building your Consul cluster inside a VPC created from [this
module](https://github.com/EmpaticoOrg/tf_vpc).

See `interface.tf` for additional configurable variables.

## License

Modified from Hashicorp's [original](https://github.com/hashicorp/consul/tree/master/terraform/aws) with thanks to the team there and other contributors for their excellent work. Any broken bits are entirely my fault.

MIT
