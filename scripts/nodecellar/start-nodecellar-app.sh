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


TEMP_DIR='/tmp'
PID_FILE='/tmp/nodecellar.pid'
NODEJS_ROOT=$(ctx instance runtime_properties node_js_root)
NODECELLAR_SOURCE_PATH=$(ctx instance runtime_properties nodecellar_source_path)
STARTUP_SCRIPT=$(ctx node properties startup_script)

COMMAND="${NODEJS_ROOT}/bin/node ${NODECELLAR_SOURCE_PATH}/${STARTUP_SCRIPT}"

export NODECELLAR_PORT=$(ctx node properties port)
export MONGO_HOST=$(ctx instance runtime_properties mongo_ip_address)
export MONGO_PORT=$(ctx instance runtime_properties mongo_port)

ctx logger info "MongoDB is located at: ${MONGO_HOST}:${MONGO_PORT}"
ctx logger info "Starting nodecellar application on port ${NODECELLAR_PORT}"

ctx logger info "${COMMAND}"
nohup ${COMMAND} > /dev/null 2>&1 &
echo $! > ${PID_FILE}

wait_for_server ${NODECELLAR_PORT} 'Nodecellar'

# this runtime porperty is used by the stop-nodecellar-app.sh script.
ctx instance runtime_properties pid_file ${PID_FILE}

ctx logger info "Sucessfully started nodecellar[pid=`cat ${PID_FILE}`]"
