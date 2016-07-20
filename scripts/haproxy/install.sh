#!/bin/bash -e

ctx logger info "Installing HAProxy"

if command -v yum > /dev/null 2>&1; then
    sudo yum install -y haproxy
elif command -v apt-get > /dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get -y install haproxy
    sudo /bin/sed -i s/ENABLED=0/ENABLED=1/ /etc/default/haproxy
else
    ctx abort-operation "Unsupported distribution"
fi

ctx logger info "Installed HAProxy"
