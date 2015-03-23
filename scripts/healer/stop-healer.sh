#! /bin/bash
pip install influxdb
if [ $? -gt 0 ]; then 
  ctx logger info "Aborting ... "
  exit
fi


NTM="$(ctx node properties nodes_to_monitor)"
NTM=$(echo ${NTM} | sed "s/u'/'/g")
DPLID=$(ctx deployment id)

LOC=$(ctx download-resource scripts/healer.py)

COMMAND="/home/ubuntu/cloudify.${DPLID}/env/bin/python ${LOC} \"${NTM}\" ${DPLID}"

ctx logger info "Running ${COMMAND}"
nohup ${COMMAND} > /dev/null 2>&1 &

#echo "*/1 * * * * $COMMAND" >> /home/ubuntu/mycron
#crontab /home/ubuntu/mycron
