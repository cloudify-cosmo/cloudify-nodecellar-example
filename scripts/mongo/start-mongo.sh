#!/bin/bash

function wait_for_server() {

    port=$1
    server_name=$2

    started=false

    for i in $(seq 1 120)
    do
        if wget http://localhost:${port} 2>/dev/null ; then
            STARTED=true
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
PID_FILE='/tmp/mongo.pid'

PORT=$(ctx node properties port)
MONGO_ROOT_PATH=$(ctx instance runtime_properties mongo_root_path)
COMMAND="./mongodb/bin/mongod --port ${PORT} --dbpath data --rest --journal --shardsvr"

cd ${MONGO_ROOT_PATH} || exit $?

ctx logger info ${COMMAND}
nohup ./mongodb/bin/mongod --port ${PORT} --dbpath data --rest --journal --shardsvr > /dev/null 2>&1 &
echo $! > ${PID_FILE}

ctx logger info "Waiting for MongoDB to launch"

REST_PORT=`expr ${port} + 1000`
wait_for_server ${REST_PORT} 'MongoDB'

ctx logger info "MongDB started sucessfully[pid=`cat ${PID_FILE}`"
