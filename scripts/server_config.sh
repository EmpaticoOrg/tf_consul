#!/usr/bin/env bash
set -e

# Read from the file we created
SERVER_COUNT=$(cat /tmp/consul-server-count | tr -d '\n')
CONSUL_JOIN=$(cat /tmp/consul-server-addr | tr -d '\n')
NODE_NAME=$(cat /tmp/consul-node-name | tr -d '\n')
DATACENTER=$(cat /tmp/consul-datacenter | tr -d '\n')
MASTERTOKEN=$(cat /tmp/consul-mastertoken | tr -d '\n')
ENCRYPTION_KEY=$(cat /tmp/consul-encryption-key | tr -d '\n')
sudo rm /tmp/consul-encryption-key
sudo rm /tmp/consul-mastertoken

# Write the config file

cat >/tmp/config.json << EOF
{
  "data_dir": "/var/consul",
  "node_name": "${NODE_NAME}",
  "datacenter": "${DATACENTER}",
  "server": true,
  "addresses": {
    "http": "0.0.0.0",
    "dns": "0.0.0.0"
  },
  "ports": {
    "dns": 53
  },
  "bootstrap_expect": ${SERVER_COUNT},
  "enable_syslog": true,
  "start_join": ["${CONSUL_JOIN}"],
  "encrypt": "${ENCRYPTION_KEY}",
  "acl_datacenter":"${DATACENTER}",
  "acl_default_policy":"deny",
  "acl_down_policy":"deny",
  "acl_master_token":"${MASTERTOKEN}"
}
EOF

sudo mv /tmp/config.json /etc/consul/conf.d/config.json

# Write the flags to a temporary file
cat >/tmp/consul_flags << EOF
CONSUL_FLAGS="-config-dir=/etc/consul/conf.d"
EOF

