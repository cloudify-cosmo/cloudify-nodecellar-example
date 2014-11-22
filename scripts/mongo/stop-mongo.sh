#!/bin/bash

TEMP_DIR='/tmp'
PID_FILE='/tmp/mongo.pid'
MONGO_ROOT_PATH=$(ctx instance runtime_properties mongo_root_path)

PID=`cat ${PID_FILE}`

ctx logger info "Stopping MongoDB process[pid=${PID}]"
kill -9 ${PID} || exit $?

ctx logger info "Deleting pid file from ${PID_FILE}"
rm ${PID_FILE}