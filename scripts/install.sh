#!/usr/bin/env bash
set -e

sudo apt-get update -y
sudo apt-get install -y unzip

echo "Fetching Consul..."
CONSUL=0.7.1
cd /tmp
curl https://releases.hashicorp.com/consul/${CONSUL}/consul_${CONSUL}_linux_amd64.zip -o consul.zip

echo "Installing Consul..."
unzip consul.zip >/dev/null
chmod +x consul
sudo mv consul /usr/local/bin/consul
sudo mkdir -p /var/consul
sudo mkdir -p /etc/consul/conf.d

