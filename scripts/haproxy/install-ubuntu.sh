#!/bin/bash -e

ctx logger info "Installing HAProxy"
ctx logger debug "${COMMAND}"

sudo apt-get update
sudo apt-get -y install haproxy

sudo /bin/sed -i s/ENABLED=0/ENABLED=1/ /etc/default/haproxy

ctx logger info "Installed HAProxy"
