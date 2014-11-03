#!/bin/bash

TEMP_DIR="/tmp"
MONGO_ROOT=${TEMP_DIR}/$(ctx execution-id)/mongodb
PID_FILE="/tmp/mongo.pid"

PID=`cat ${PID_FILE}`
ctx logger info "Shutting down mongo. pid = ${PID}"
kill -9 ${PID} || exit $?
ctx logger info "Removing PID file from ${PID_FILE}"
rm ${PID_FILE}