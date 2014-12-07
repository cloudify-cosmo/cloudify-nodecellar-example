#!/bin/bash

set -e

function download() {

   url=$1
   name=$2

   if [ -f "`pwd`/${name}" ]; then
        ctx logger info "`pwd`/${name} already exists, No need to download"
   else
        # download to given directory
        ctx logger info "Downloading ${url} to `pwd`/${name}"

        set +e
        curl_cmd=$(which curl)
        wget_cmd=$(which wget)
        set -e

        if [[ ! -z ${curl_cmd} ]]; then
            curl -L -o ${name} ${url}
        elif [[ ! -z ${wget_cmd} ]]; then
            wget -O ${name} ${url}
        else
            ctx logger error "Failed to download ${url}: Neither 'cURL' nor 'wget' were found on the system"
            exit 1;
        fi
   fi

}


function untar() {

    tar_archive=$1
    destination=$2

    if [ ! -d ${destination} ]; then
        inner_name=$(tar -tf "${tar_archive}" | grep -o '^[^/]\+' | sort -u)
        ctx logger info "Untaring ${tar_archive}"
        tar -zxvf ${tar_archive}

        ctx logger info "Moving ${inner_name} to ${destination}"
        mv ${inner_name} ${destination}
    fi
}

TEMP_DIR='/tmp'
MONGO_TARBALL_NAME='mongodb-linux-x86_64-2.4.9.tgz'

################################
# Directory that will contain:
#  - MongoDB binaries
#  - MongoDB Database files
################################
MONGO_ROOT_PATH=${TEMP_DIR}/$(ctx execution-id)/mongodb
MONGO_DATA_PATH=${MONGO_ROOT_PATH}/data
MONGO_BINARIES_PATH=${MONGO_ROOT_PATH}/mongodb-binaries
mkdir -p ${MONGO_ROOT_PATH}

cd ${TEMP_DIR}
download http://downloads.mongodb.org/linux/${MONGO_TARBALL_NAME} ${MONGO_TARBALL_NAME}
untar ${MONGO_TARBALL_NAME} ${MONGO_BINARIES_PATH}

ctx logger info "Creating MongoDB data directory in ${MONGO_DATA_PATH}"
mkdir -p ${MONGO_DATA_PATH}

# these runtime properties are used by the start-mongo script.
ctx instance runtime-properties mongo_root_path ${MONGO_ROOT_PATH}
ctx instance runtime-properties mongo_binaries_path ${MONGO_BINARIES_PATH}
ctx instance runtime-properties mongo_data_path ${MONGO_DATA_PATH}

ctx logger info "Sucessfully installed MongoDB"
