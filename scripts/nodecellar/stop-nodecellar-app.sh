#!/bin/bash

set -e

PID_FILE=$(ctx instance runtime_properties pid_file)
PID=`cat ${PID_FILE}`

ctx logger info "Stopping Nodecellar process[pid = ${PID}]"
kill -9 ${PID}

ctx logger info "Stopped nodecellar application :-)"
ctx logger info "Removing PID file from ${PID_FILE}"
rm ${PID_FILE}

ctx logger info "Sucessfully stopped Nodecellar"