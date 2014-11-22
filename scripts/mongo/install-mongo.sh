#!/bin/bash

function install_curl() {

    yum_cmd=$(which yum)
    apt_get_cmd=$(which apt-get)

    if [[ ! -z ${yum_cmd} ]]; then
        sudo yum -y install curl || exit $?
    elif [[ ! -z ${apt_get_cmd} ]]; then
        sudo apt-get -qq install curl || exit $?
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
       ctx logger info "Downloading ${name} to `pwd`/${name}"
       curl -O ${url}
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

TEMP_DIR='/tmp'
MONGO_TARBALL_NAME='mongodb-linux-x86_64-2.4.9.tgz'
MONGO_ROOT_PATH=${TEMP_DIR}/$(ctx execution-id)/mongodb

mkdir -p ${MONGO_ROOT_PATH} || exit $?
cd ${MONGO_ROOT_PATH} || exit $?

install_curl

download http://downloads.mongodb.org/linux/${MONGO_TARBALL_NAME} ${MONGO_TARBALL_NAME}
untar ${MONGO_TARBALL_NAME} mongodb-linux-x86_64-2.4.9 mongodb-binaries

ctx logger info "Creating MongoDB data directory --> `pwd`/data"
mkdir -p data || exit $?

ctx logger info "Sucessfully installed MongoDB"

# set runtime property to enable access for susequent scripts
ctx instance runtime-properties mongo_root_path ${MONGO_ROOT_PATH}