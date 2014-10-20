#!/bin/bash

TEMP_DIR="/tmp"
MONGO_ROOT=${TEMP_DIR}/$(ctx execution-id)/mongodb
MONGO_TARBALL=mongodb-linux-x86_64-2.4.9.tgz

if [ ! -f ${MONGO_ROOT} ]; then
    mkdir -p ${MONGO_ROOT} || exit $?    
fi

ctx logger info "Changing directory to ${MONGO_ROOT}"
cd ${MONGO_ROOT} || exit $?

ctx logger info "Downloading mongodb to ${MONGO_ROOT}"
if [ -f ${MONGO_TARBALL} ]; then
    ctx logger info "Mongo tarball already exists, skipping"   
else
    curl -O http://downloads.mongodb.org/linux/${MONGO_TARBALL}
fi

if [ ! -d mongodb ]; then
    ctx logger info "Untaring mongodb"
    tar -zxvf mongodb-linux-x86_64-2.4.9.tgz || exit $?

    ctx logger info "Moving mongo distro to ${MONGO_ROOT}/mongodb"
    mv mongodb-linux-x86_64-2.4.9 mongodb || exit $?
fi

ctx logger info "Creating mongodb data dir at ${MONGO_ROOT}/data"
if [ -d data ]; then
    ctx logger info "Mongodb data dir already exists, skipping"
else 
    mkdir -p data || exit $?    
fi 

ctx logger info "Finished installing mongodb"

