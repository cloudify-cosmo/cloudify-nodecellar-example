#!/bin/bash

TEMP_DIR="/tmp"
MONGO_ROOT=${TEMP_DIR}/$(ctx execution-id)/mongodb
PID_FILE="mongo.pid"

PID=`cat ${MONGO_ROOT}/${PID_FILE}`
ctx logger info "Shutting down mongo. pid = ${PID}"
kill -9 ${PID} || exit $?
