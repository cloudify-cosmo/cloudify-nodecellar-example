#!/bin/bash

TEMP_DIR="/tmp"
NODEJS_ROOT=${TEMP_DIR}/$(ctx execution-id)/nodejs
NODEJS_TARBALL=node-v0.10.26-linux-x64.tar.gz

if [ ! -f ${NODEJS_ROOT} ]; then
    mkdir -p ${NODEJS_ROOT} || exit $?    
fi

YUM_CMD=$(which yum)
APT_GET_CMD=$(which apt-get)

ctx logger info "Changing directory to ${NODEJS_ROOT}"
cd ${NODEJS_ROOT} || exit $?

ctx logger info "Downloading nodejs to ${NODEJS_ROOT}"
if [ -f ${NODEJS_TARBALL} ]; then
    ctx logger info "Nodejs tarball already exists, skipping"   
else
    if [[ ! -z $YUM_CMD ]]; then
        sudo yum -y install curl || exit $?   
    elif [[ ! -z $APT_GET_CMD ]]; then
        sudo apt-get -qq install curl || exit $?   
    else
        ctx logger error "can't install package git"
        exit 1;
    fi

    curl -O http://nodejs.org/dist/v0.10.26/${NODEJS_TARBALL} || exit $?
fi

if [ ! -d nodejs ]; then
    ctx logger info "Untaring nodejs"
    tar -zxvf node-v0.10.26-linux-x64.tar.gz || exit $?

    ctx logger info "Moving nodejs distro to ${NODEJS_ROOT}/nodejs"
    mv node-v0.10.26-linux-x64 nodejs || exit $?
fi

ctx logger info "Finished installing nodejs"

