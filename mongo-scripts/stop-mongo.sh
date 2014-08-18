#!/bin/bash

function info(){ builtin echo [INFO] [$(basename $0)] $@; }
function error(){ builtin echo [ERROR] [$(basename $0)] $@; }

#. ${CLOUDIFY_LOGGING}
#. ${CLOUDIFY_FILE_SERVER}


TEMP_DIR="/tmp"
MONGO_ROOT=${TEMP_DIR}/${CLOUDIFY_EXECUTION_ID}/mongodb
PID_FILE="mongo.pid"

PID=`cat ${MONGO_ROOT}/${PID_FILE}`
info "Shutting down mongo. pid = ${PID}"
kill -9 ${PID} || exit $?