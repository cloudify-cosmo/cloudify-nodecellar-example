#! /bin/bash

# note this currently means that healers belonging to different deployments
# will be affected. should create a different healer.py file per deployment
ctx logger info "Removing healer process from crontab"
crontab -l | grep -v healer | crontab
deployment_id=$(ctx deployment id)
rm "${deployment_id}-healer.log"
rm "${deployment_id}-healer.state"