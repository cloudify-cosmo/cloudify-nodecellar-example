#!/bin/bash

set -e

function wait_for_server() {

    port=$1
    server_name=$2

    started=false

    ctx logger info "Running ${server_name} liveness detection on port ${port}"

    for i in $(seq 1 120)
    do
        if wget http://localhost:${port} 2>/dev/null ; then
            started=true
            break
        else
            ctx logger info "${server_name} has not started. waiting..."
            sleep 1
        fi
    done
    if [ ${started} = false ]; then
        ctx logger error "${server_name} failed to start. waited for a 120 seconds."
        exit 1
    fi

}

PID_FILE='/tmp/mongo.pid'
PORT=$(ctx node properties port)
MONGO_BINARIES_PATH=$(ctx instance runtime_properties mongo_binaries_path)
MONGO_DATA_PATH=$(ctx instance runtime_properties mongo_data_path)
COMMAND="${MONGO_BINARIES_PATH}/bin/mongod --port ${PORT} --dbpath ${MONGO_DATA_PATH} --rest --journal --shardsvr"

ctx logger info "${COMMAND}"
nohup ${COMMAND} > /dev/null 2>&1 &
echo $! > ${PID_FILE}

MONGO_REST_PORT=`expr ${PORT} + 1000`
wait_for_server ${MONGO_REST_PORT} 'MongoDB'

# this runtime porperty is used by the stop-mongo script.
ctx instance runtime_properties pid_file ${PID_FILE}

ctx logger info "Sucessfully started MongDB[pid=`cat ${PID_FILE}`]"
