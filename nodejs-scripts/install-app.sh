#!/bin/bash

TEMP_DIR="/tmp"
BASE_DIR=${TEMP_DIR}/$(ctx execution-id)
NODEJS_ROOT=${BASE_DIR}/nodejs

ctx logger info "Changing directory to ${BASE_DIR}"
cd ${BASE_DIR} || exit $?

YUM_CMD=$(which yum)
APT_GET_CMD=$(which apt-get)

ctx logger info "Downloading application sources to ${BASE_DIR}"
if [ -f nodecellar ]; then
    ctx logger info "Application sources already exists, skipping"   
else
    if [[ ! -z $YUM_CMD ]]; then
        sudo yum -y install git-core || exit $?   
    elif [[ ! -z $APT_GET_CMD ]]; then 
        sudo apt-get -qq install git || exit $?   
     else
        ctx logger error "error can't install package git"
        exit 1;
     fi

    git_url=$(ctx node properties git_url)
    git_branch=$(ctx node properties git_branch)

    ctx logger info "cloning application from git url ${git_url}"
    if [[ ! -z "$git_branch" ]]; then
        git clone ${git_url} || exit $?
    else
	ctx logger info "checking out branch ${git_branch}"
	git clone ${git_url} -b ${git_branch} || exit $?
    fi

    cd nodecellar || exit $?
    if [[ ! -z $git_branch ]]; then
        ctx logger info "checking out branch ${git_branch}" 
        git checkout ${git_branch} || exit $?
    fi 
    ctx logger info "Installing application modules using npm" 
    ${NODEJS_ROOT}/nodejs/bin/npm install --silent || exit $?
fi

app_name=$(ctx node properties app_name)
ctx logger info "Finished installing application ${app_name}"

