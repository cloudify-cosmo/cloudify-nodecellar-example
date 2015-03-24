#! /bin/bash

# note this currently means that healers belonging to different deployments
# will be affected. should create a different scaler.py file per deployment
ctx logger info "Removing scaler process from crontab"
crontab -l | grep -v scaler | crontab