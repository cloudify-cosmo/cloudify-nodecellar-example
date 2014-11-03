#!/bin/bash

PID_FILE="/tmp/nodejs.pid"

PID=`cat ${PID_FILE}`
ctx logger info "Shutting down nodejs. pid = ${PID}"
kill -9 ${PID} || exit $?

ctx logger info "Stopped nodecellar application :-)"
ctx logger info "Removing PID file from ${PID_FILE}"
rm ${PID_FILE}