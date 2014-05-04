#!/bin/bash

function info(){ builtin echo [INFO] [$(basename $0)] $@; }
function error(){ builtin echo [ERROR] [$(basename $0)] $@; }


#. ${CLOUDIFY_LOGGING}
#. ${CLOUDIFY_FILE_SERVER}

TEMP_DIR="/tmp"
APP_ROOT=${TEMP_DIR}/${app_name}
PID_FILE="nodejs.pid"

info "Changing directory to ${APP_ROOT}"
cd ${APP_ROOT} || exit $?

. /tmp/mongo_host_and_port.sh

export NODECELLAR_PORT=${base_port}

info "Mongo url is ${MONGO_HOST}:${MONGO_PORT}"
info "Nodecellar app starting on port ${NODECELLAR_PORT}"

nohup /tmp/nodejs/nodejs/bin/node server.js > /dev/null 2>&1 &
echo $! > ${PID_FILE}

info "Started nodejs, pid is `cat ${PID_FILE}`"


