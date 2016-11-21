#!/usr/bin/env bash
set -e

# Read from the file we created
SERVER_COUNT=$(cat /tmp/consul-server-count | tr -d '\n')
CONSUL_JOIN=$(cat /tmp/consul-server-addr | tr -d '\n')
NODE_NAME=$(cat /tmp/consul-node-name | tr -d '\n')
ENCRYPTION_KEY=$(cat /tmp/consul-encryption-key | tr -d '\n')
sudo rm /tmp/consul-encryption-key

# Write the config file

cat >/tmp/config.json << EOF
{
  "data_dir": "/var/consul",
  "node_name": "${NODE_NAME}",
  "server": true,
  "bootstrap_expect": ${SERVER_COUNT},
  "enable_syslog": true,
  "start_join": ["${CONSUL_JOIN}"],
  "encrypt": "${ENCRYPTION_KEY}"
}
EOF

sudo mv /tmp/config.json /etc/consul/conf.d/config.json

# Write the flags to a temporary file
cat >/tmp/consul_flags << EOF
CONSUL_FLAGS="-config-dir=/etc/consul/conf.d"
EOF

