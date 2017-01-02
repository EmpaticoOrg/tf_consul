#!/bin/bash

cat >/etc/consul/server.json << EOF
{
  "retry_join_ec2": {
	  "tag_key": "Flag",
	  "tag_value": "consul"
	},
  "bootstrap_expect": 3,
  "node_name": "$${HOSTNAME}",
  "datacenter": "${environment}",
  "server": true,
  "addresses": {
    "http": "0.0.0.0",
    "dns": "0.0.0.0"
  },
  "encrypt": "${encryption_key}",
  "acl_datacenter":"${environment}",
  "acl_default_policy":"deny",
  "acl_down_policy":"deny",
  "acl_master_token":"${mastertoken}"
}
EOF

systemctl restart consul
