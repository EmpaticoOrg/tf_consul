#!/usr/bin/env bash
set -e

if [ -f /tmp/upstart.conf ];
then
  echo "Installing Upstart service..."
  sudo mkdir -p /etc/consul.d
  sudo mkdir -p /etc/service
  sudo chown root:root /tmp/upstart.conf
  sudo mv /tmp/upstart.conf /etc/init/consul.conf
  sudo chmod 0644 /etc/init/consul.conf
  sudo mv /tmp/consul_flags /etc/service/consul
  sudo chmod 0644 /etc/service/consul
else
  echo "Installing Systemd service..."
  sudo chown root:root /tmp/consul.service
  sudo mv /tmp/consul.service /etc/systemd/system/consul.service
  sudo chmod 0644 /etc/systemd/system/consul.service
  if [ -x "$(command -v apt-get)" ]; then
    sudo mv /tmp/consul_flags /etc/default/consul
    sudo chown root:root /etc/default/consul
    sudo chmod 0644 /etc/default/consul
  else
    sudo mv /tmp/consul_flags /etc/sysconfig/consul
    sudo chown root:root /etc/sysconfig/consul
    sudo chmod 0644 /etc/sysconfig/consul
  fi
fi

echo "Starting Consul..."
if [ -x "$(command -v systemctl)" ]; then
  echo "using systemctl"
  sudo systemctl enable consul.service
  sudo systemctl start consul
else
  echo "using upstart"
  sudo start consul
fi
