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

       # -L handles Github redirects.
       curl -L -o ${name} ${url}
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
NODEJS_ROOT=$(ctx instance runtime_properties node_js_root)
ORGANIZATION=$(ctx node properties organization)
REPO_NAME=$(ctx node properties repo)
BRANCH=$(ctx node properties branch)
APPLICATION_URL="https://github.com/${ORGANIZATION}/${REPO_NAME}/archive/${BRANCH}.tar.gz"

################################
# Directory that will contain:
#  - Nodecellar source
################################
NODECELLAR_ROOT_PATH=${TEMP_DIR}/$(ctx execution-id)/nodecellar
mkdir -p ${NODECELLAR_ROOT_PATH}

cd ${TEMP_DIR}
download ${APPLICATION_URL} ${BRANCH}.tar.gz
untar ${BRANCH}.tar.gz ${REPO_NAME}-${BRANCH} ${NODECELLAR_ROOT_PATH}/nodecellar-source

cd ${NODECELLAR_ROOT_PATH}/nodecellar-source
ctx logger info "Installing nodecellar dependencies using npm"
${NODEJS_ROOT}/bin/npm install

ctx instance runtime_properties nodecellar_source_path ${NODECELLAR_ROOT_PATH}/nodecellar-source

ctx logger info "Sucessfully installed nodecellar"
