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

    inner_name=$(tar -tf "${tar_archive}" | grep -o '^[^/]\+' | sort -u)

    if [ ! -d ${destination} ]; then
        ctx logger info "Untaring ${tar_archive}"
        tar -zxvf ${tar_archive}

        ctx logger info "Moving ${inner_name} to ${destination}"
        mv ${inner_name} ${destination}
    fi
}

TEMP_DIR='/tmp'
NODEJS_TARBALL_NAME='node-v0.10.26-linux-x64.tar.gz'

################################
# Directory that will contain:
#  - NodeJS binaries
################################
NODEJS_ROOT=${TEMP_DIR}/$(ctx execution-id)/nodejs
NODEJS_BINARIES_PATH=${NODEJS_ROOT}/nodejs-binaries
mkdir -p ${NODEJS_ROOT}

cd ${TEMP_DIR}
download http://nodejs.org/dist/v0.10.26/${NODEJS_TARBALL_NAME} ${NODEJS_TARBALL_NAME}
untar ${NODEJS_TARBALL_NAME} ${NODEJS_BINARIES_PATH}

# this runtime property is used by the start-nodecellar-app.sh
ctx instance runtime_properties nodejs_binaries_path ${NODEJS_BINARIES_PATH}

ctx logger info "Sucessfully installed NodeJS"

