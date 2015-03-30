#! /bin/bash

# note this currently means that healers belonging to different deployments
# will be affected. should create a different scaler.py file per deployment
ctx logger info "Removing scaler process from crontab"
crontab -l | grep -v scaler | crontab
deployment_id=$(ctx deployment id)
rm "${deployment_id}-scaler.log"
rm "${deployment_id}-scaler.state"