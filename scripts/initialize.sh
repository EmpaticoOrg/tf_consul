#!/bin/bash

internalIP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
instanceID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
hostname="consul-$${instanceID#*-}"

hostnamectl set-hostname $hostname

aws ec2 describe-instances --region ${region} --filters 'Name=tag:Flag,Values=consul' 'Name=instance-state-name,Values=running' | jq -r '.Reservations[].Instances[].PrivateIpAddress' > /tmp/instances

cat >/etc/consul.d/server.json << EOF
{
  "data_dir": "/var/consul",
  "bootstrap_expect": 3,
  "node_name": "$${hostname}",
  "datacenter": "${environment}",
  "server": true,
  "addresses": {
    "http": "0.0.0.0",
    "dns": "0.0.0.0"
  },
  "ports": {
    "dns": 53
  },
  "encrypt": "${encryption_key}",
  "acl_datacenter":"${environment}",
  "acl_default_policy":"deny",
  "acl_down_policy":"deny",
  "acl_master_token":"${mastertoken}"
}
EOF

while read line;
do
 if [ "$line" != "$internalIP" ]; then
    echo "Adding address $line"
    cat /etc/consul.d/server.json | jq ".retry_join += [\"$line\"]" > /tmp/$${line}-consul.json

    if [ -s /tmp/$${line}-consul.json ]; then
        cp /tmp/$${line}-consul.json /etc/consul.d/server.json
    fi
 fi
done < /tmp/instances
rm -f /tmp/instances

# Clear any old state from the build process
rm -rf /var/consul/*

systemctl stop consul
systemctl start consul
