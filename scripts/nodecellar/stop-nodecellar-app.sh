#!/bin/bash

set -e

PID=$(ctx instance runtime_properties pid)

kill -9 ${PID}

ctx logger info "Sucessfully stopped Nodecellar (${PID})"