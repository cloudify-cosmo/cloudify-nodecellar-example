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
NODEJS_TARBALL_NAME='node-v0.10.26-linux-x64.tar.gz'

################################
# Directory that will contain:
#  - NodeJS binaries
################################
NODEJS_ROOT=${TEMP_DIR}/$(ctx execution-id)/nodejs
mkdir -p ${NODEJS_ROOT}

cd ${TEMP_DIR}
download http://nodejs.org/dist/v0.10.26/${NODEJS_TARBALL_NAME} ${NODEJS_TARBALL_NAME}
untar node-v0.10.26-linux-x64.tar.gz node-v0.10.26-linux-x64 ${NODEJS_ROOT}/nodejs-binaries

# this runtime property is used by the start-nodecellar-app.sh
ctx instance runtime_properties node_js_root ${NODEJS_ROOT}/nodejs-binaries

ctx logger info "Sucessfully installed NodeJS"

