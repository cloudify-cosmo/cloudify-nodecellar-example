#!/bin/bash

TEMP_DIR='/tmp'
PID_FILE='/tmp/nodejs.pid'

APP_ROOT=${TEMP_DIR}/$(ctx execution-id)/nodecellar
NODEJS_ROOT=${TEMP_DIR}/$(ctx execution-id)/nodejs

export NODECELLAR_PORT=$(ctx node properties port)

# these are injected by the script plugin
export MONGO_HOST=${MONGO_HOST}
export MONGO_PORT=${MONGO_PORT}

ctx logger info "MongoDB is located at: ${MONGO_HOST}:${MONGO_PORT}"
ctx logger info "Starting nodecellar application on port ${NODECELLAR_PORT}"

cd ${APP_ROOT} || exit $?
nohup ${NODEJS_ROOT}/nodejs/bin/node server.js > /dev/null 2>&1 &

echo $! > ${PID_FILE}

ctx logger info "Started Nodecellar application succesfully[pid=`cat ${PID_FILE}`]"
