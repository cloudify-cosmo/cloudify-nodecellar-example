#!/bin/bash

TEMP_DIR="/tmp"
MONGO_ROOT=${TEMP_DIR}/$(ctx execution-id)/mongodb
PID_FILE="mongo.pid"

ctx logger info "Changing directory to ${MONGO_ROOT}"
cd ${MONGO_ROOT} || exit $?

port=$(ctx node properties port)

ctx logger info "Starting mongodb from ${MONGO_ROOT}/mongodb/bin/mongod with port ${port}"
nohup ./mongodb/bin/mongod --port ${port} --dbpath data --rest --journal --shardsvr > /dev/null 2>&1 &
echo $! > ${PID_FILE}

ctx logger info "Waiting for mongo to launch"

STARTED=false
REST_PORT=`expr ${port} + 1000`
for i in $(seq 1 120)
do
    if wget http://localhost:${REST_PORT} 2>/dev/null ; then
        ctx logger info "Server is up."
        STARTED=true
        break
    else
        ctx logger info "mongodb not up. waiting 1 second."
        sleep 1
    fi  
done
if [ ${STARTED} = false ]; then
    ctx logger error "Failed to start mongodb in 120 seconds."
    exit 1
fi
# Installing jq to parse json 
ctx logger info "Installing jq"
if [ ! -f ./jq ]; then
    wget http://stedolan.github.io/jq/download/linux64/jq || exit $?
    chmod +x ./jq || exit $?
    ctx logger info "jq installed sucessfully"
else 
    ctx logger info "Skipping, jq already installed"
fi

IP_ADDR=$(ip addr | grep inet | grep eth0 | awk -F" " '{print $2}'| sed -e 's/\/.*$//')
ctx logger info "About to post IP address ${IP_ADDR} and port ${port}"

ctx instance runtime-properties port ${port}
ctx instance runtime-properties ip_address ${IP_ADDR}

