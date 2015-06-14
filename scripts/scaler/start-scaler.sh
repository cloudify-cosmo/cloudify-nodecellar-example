#! /bin/bash
pip install influxdb
if [ $? -gt 0 ]; then 
  ctx logger info "Aborting ... "
  exit
fi

HOME="/root"

nodejs_host_node_name=$(ctx node properties nodejs_host_node_name)
mongo_node_name=$(ctx node properties mongo_node_name)
deployment_id=$(ctx deployment id)
threshold=$(ctx node properties threshold)
deployment_id=$(ctx deployment id)

scaler_path=$(ctx download-resource scripts/scaler/scaler.py)

COMMAND="${HOME}/cloudify.${deployment_id}/env/bin/python ${scaler_path} ${nodejs_host_node_name} ${mongo_node_name} ${deployment_id} ${threshold}"

ctx logger info "Adding scaler process to crontab with command ${COMMAND}"
echo "*/1 * * * * ${COMMAND}" >> "${HOME}/${deployment_id}-cron"
crontab "${HOME}/${deployment_id}-cron"
