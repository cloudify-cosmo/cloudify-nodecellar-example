#!/bin/bash

function info(){ builtin echo [INFO] [$(basename $0)] $@; }
function error(){ builtin echo [ERROR] [$(basename $0)] $@; }


#. ${CLOUDIFY_LOGGING}
#. ${CLOUDIFY_FILE_SERVER}

TEMP_DIR="/tmp"
MONGO_ROOT=${TEMP_DIR}/mongodb
MONGO_TARBALL=mongodb-linux-x86_64-2.4.9.tgz
BLUEPRINT_PATH=blueprints/${CLOUDIFY_BLUEPRINT_ID}

if [ ! -f ${MONGO_ROOT} ]; then
    mkdir -p ${MONGO_ROOT} || exit $?    
fi


info "Changing directory to ${MONGO_ROOT}"
cd ${MONGO_ROOT} || exit $?

info "Downloading mongodb to ${MONGO_ROOT}"
if [ -f ${MONGO_TARBALL} ]; then
    info "Mongo tarball already exists, skipping"   
else
    curl -O http://downloads.mongodb.org/linux/${MONGO_TARBALL}
fi

if [ ! -d mongodb ]; then
    info "Untaring mongodb"
    tar -zxvf mongodb-linux-x86_64-2.4.9.tgz || exit $?

    info "Moving mongo distro to ${MONGO_ROOT}/mongodb"
    mv mongodb-linux-x86_64-2.4.9 mongodb || exit $?
fi

info "Creating mongodb data dir at ${MONGO_ROOT}/data"
if [ -d data ]; then
    info "Mongodb data dir already exists, skipping"
else 
    mkdir -p data || exit $?    
fi 

info "Finished installing mongodb"

