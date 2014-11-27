#!/bin/bash

function install_curl() {

    yum_cmd=$(which yum)
    apt_get_cmd=$(which apt-get)

    if [[ ! -z ${yum_cmd} ]]; then
        ctx logger info "Installing package: curl"
        sudo yum -y install curl || exit $?
        ctx logger info "Succesfully installed package: curl"
    elif [[ ! -z ${apt_get_cmd} ]]; then
        ctx logger info "Installing package: curl"
        sudo apt-get -qq install curl || exit $?
        ctx logger info "Succesfully installed package: curl"
    else
        ctx logger error 'No package manager available to install package: curl'
        exit 1;
    fi

}

function download() {

   url=$1
   name=$2

   if [ -f "`pwd`/${name}" ]; then
        ctx logger info "`pwd`/${name} already exists, No need to download"
   else
       # download to given directory
       ctx logger info "Downloading ${url} to `pwd`/${name}"
       curl -o ${name} ${url}
   fi
}

function untar() {

    tar_archive=$1
    inner_name=$2
    destination=$3

    if [ ! -d ${destination} ]; then
        ctx logger info "Untaring ${tar_archive}"
        tar -zxvf ${tar_archive} || exit $?

        ctx logger info "Moving to ${destination}"
        mv ${inner_name} ${destination} || exit $?
    fi
}

install_curl

set -e

TEMP_DIR='/tmp'
MONGO_TARBALL_NAME='mongodb-linux-x86_64-2.4.9.tgz'

################################
# Directory that will contain:
#  - MongoDB binaries
#  - MongoDB Database files
################################
MONGO_ROOT_PATH=${TEMP_DIR}/$(ctx execution-id)/mongodb
mkdir -p ${MONGO_ROOT_PATH}

cd ${TEMP_DIR}
download http://downloads.mongodb.org/linux/${MONGO_TARBALL_NAME} ${MONGO_TARBALL_NAME}
untar ${MONGO_TARBALL_NAME} mongodb-linux-x86_64-2.4.9 ${MONGO_ROOT_PATH}/mongodb-binaries

cd ${MONGO_ROOT_PATH}
ctx logger info "Creating MongoDB data directory --> `pwd`/data"
mkdir -p data

# these runtime properties are used by the start-mongo script.
ctx instance runtime-properties mongo_path ${MONGO_ROOT_PATH}
ctx instance runtime-properties mongo_binaries_path ${MONGO_ROOT_PATH}/mongodb-binaries
ctx instance runtime-properties mongo_data_path ${MONGO_ROOT_PATH}/data

ctx logger info "Sucessfully installed MongoDB"
