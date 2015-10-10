#!/bin/bash

set -e

if [ "$mongo_ip_address" = "" ];then
    mongo_ip_address=$(ctx target instance host_ip)
fi

ctx source instance runtime_properties mongo_ip_address "$mongo_ip_address"
ctx source instance runtime_properties mongo_port $(ctx target node properties port)
