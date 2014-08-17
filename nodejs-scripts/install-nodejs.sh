#!/bin/bash

function info(){ builtin echo [INFO] [$(basename $0)] $@; }
function error(){ builtin echo [ERROR] [$(basename $0)] $@; }


#. ${CLOUDIFY_LOGGING}
#. ${CLOUDIFY_FILE_SERVER}

TEMP_DIR="/tmp"
NODEJS_ROOT=${TEMP_DIR}/${CLOUDIFY_EXECUTION_ID}/nodejs
NODEJS_TARBALL=node-v0.10.26-linux-x64.tar.gz
BLUEPRINT_PATH=blueprints/${CLOUDIFY_BLUEPRINT_ID}

if [ ! -f ${NODEJS_ROOT} ]; then
    mkdir -p ${NODEJS_ROOT} || exit $?    
fi

YUM_CMD=$(which yum)
APT_GET_CMD=$(which apt-get)

info "Changing directory to ${NODEJS_ROOT}"
cd ${NODEJS_ROOT} || exit $?

info "Downloading nodejs to ${NODEJS_ROOT}"
if [ -f ${NODEJS_TARBALL} ]; then
    info "Nodejs tarball already exists, skipping"   
else
    if [[ ! -z $YUM_CMD ]]; then
        sudo yum -y install curl || exit $?   
    elif [[ ! -z $APT_GET_CMD ]]; then
        sudo apt-get -qq install curl || exit $?   
    else
        error "can't install package git"
        exit 1;
    fi

    curl -O http://nodejs.org/dist/v0.10.26/${NODEJS_TARBALL} || exit $?
fi

if [ ! -d mongodb ]; then
    info "Untaring nodejs"
    tar -zxvf node-v0.10.26-linux-x64.tar.gz || exit $?

    info "Moving nodejs distro to ${NODEJS_ROOT}/nodejs"
    mv node-v0.10.26-linux-x64 nodejs || exit $?
fi

info "Finished installing nodejs"

