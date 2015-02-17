#!/bin/bash -e

ctx logger info "Installing HAProxy"
ctx logger debug "${COMMAND}"

sudo apt-get update
sudo apt-get -y install haproxy

ctx logger info "Installed HAProxy"
