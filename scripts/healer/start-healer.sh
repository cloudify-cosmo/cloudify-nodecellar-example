#! /bin/bash
pip install influxdb
if [ $? -gt 0 ]; then 
  ctx logger info "Aborting ... "
  exit
fi

HOME="/root"

nodes_to_heal=$(ctx node properties nodes_to_heal)
nodes_to_heal=$(echo ${nodes_to_heal} | sed "s/u'/'/g")
deployment_id=$(ctx deployment id)

healer_path=$(ctx download-resource scripts/healer/healer.py)

COMMAND="${HOME}/cloudify.${deployment_id}/env/bin/python ${healer_path} \"${nodes_to_heal}\" ${deployment_id}"

ctx logger info "Adding healer process to crontab with command ${COMMAND}"
echo "*/1 * * * * ${COMMAND}" >> "${HOME}/${deployment_id}-cron"
crontab "${HOME}/${deployment_id}-cron"
