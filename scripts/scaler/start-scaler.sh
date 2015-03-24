#! /bin/bash
pip install influxdb
if [ $? -gt 0 ]; then 
  ctx logger info "Aborting ... "
  exit
fi


nodes_to_scale="$(ctx node properties nodes_to_scale)"
nodes_to_scale=$(echo ${nodes_to_scale} | sed "s/u'/'/g")
deployment_id=$(ctx deployment id)
service_name=$(ctx node properties service_name)
threshold=$(ctx node properties threshold)

scaler_path=$(ctx download-resource scripts/scaler.py)

COMMAND="/home/ubuntu/cloudify.${deployment_id}/env/bin/python ${scaler_path} \"${nodes_to_scale}\" ${deployment_id} ${service_name} ${threshold}"

ctx logger info "Adding scaler process to crontab"
echo "*/1 * * * * $COMMAND" >> "/home/ubuntu/${deployment_id}-healer-cron"
crontab "/home/ubuntu/${deployment_id}-scaler-cron"
