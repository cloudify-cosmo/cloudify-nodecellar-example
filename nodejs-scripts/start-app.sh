#!/bin/bash

TEMP_DIR="/tmp"
APP_ROOT=${TEMP_DIR}/$(ctx execution-id)/nodecellar
NODEJS_ROOT=${TEMP_DIR}/$(ctx execution-id)/nodejs
PID_FILE="/tmp/nodejs.pid"

ctx logger info "Changing directory to ${APP_ROOT}"
cd ${APP_ROOT} || exit $?

env_file_path=$(ctx node properties env_file_path)
if [ -z "${env_file_path}" ]; then
    . ${TEMP_DIR}/$(ctx execution-id)/mongo_host_and_port.sh
else
    . ${env_file_path}
fi

export NODECELLAR_PORT=$(ctx node properties base_port)

ctx logger info "Mongo url is ${MONGO_HOST}:${MONGO_PORT}"
ctx logger info "Nodecellar app starting on port ${NODECELLAR_PORT}"

nohup ${NODEJS_ROOT}/nodejs/bin/node server.js > /dev/null 2>&1 &
echo $! > ${PID_FILE}

ctx logger info "Started nodejs, pid is `cat ${PID_FILE}`"


