#!/bin/bash

function info(){ builtin echo [INFO] [$(basename $0)] $@; }
function error(){ builtin echo [ERROR] [$(basename $0)] $@; }


#. ${CLOUDIFY_LOGGING}
#. ${CLOUDIFY_FILE_SERVER}

TEMP_DIR="/tmp"
APP_ROOT=${TEMP_DIR}/${CLOUDIFY_EXECUTION_ID}/nodecellar
NODEJS_ROOT=${TEMP_DIR}/${CLOUDIFY_EXECUTION_ID}/nodejs
PID_FILE="nodejs.pid"

info "Changing directory to ${APP_ROOT}"
cd ${APP_ROOT} || exit $?

if [ -z "${env_file_path}" ]; then
    . ${TEMP_DIR}/${CLOUDIFY_EXECUTION_ID}/mongo_host_and_port.sh
else
    . ${env_file_path}
fi

export NODECELLAR_PORT=${base_port}

info "Mongo url is ${MONGO_HOST}:${MONGO_PORT}"
info "Nodecellar app starting on port ${NODECELLAR_PORT}"

nohup ${NODEJS_ROOT}/nodejs/bin/node server.js > /dev/null 2>&1 &
echo $! > ${PID_FILE}

info "Started nodejs, pid is `cat ${PID_FILE}`"


