#!/bin/bash

set -e

ctx source instance runtime_properties mongo_ip_address ${mongo_ip_address}

ctx source instance runtime_properties mongo_port $(ctx target node properties port)
