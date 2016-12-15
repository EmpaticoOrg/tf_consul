#!/usr/bin/env bash
set -e

echo "Installing Systemd service..."
sudo chown root:root /tmp/consul.service
sudo mv /tmp/consul.service /etc/systemd/system/consul.service
sudo chmod 0644 /etc/systemd/system/consul.service
sudo mv /tmp/consul_flags /etc/default/consul
sudo chown root:root /etc/default/consul
sudo chmod 0644 /etc/default/consul

echo "Starting Consul..."
sudo systemctl enable consul.service
sudo systemctl start consul
