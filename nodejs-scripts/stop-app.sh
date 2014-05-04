#!/bin/bash

function info(){ builtin echo [INFO] [$(basename $0)] $@; }
function error(){ builtin echo [ERROR] [$(basename $0)] $@; }


#. ${CLOUDIFY_LOGGING}
#. ${CLOUDIFY_FILE_SERVER}