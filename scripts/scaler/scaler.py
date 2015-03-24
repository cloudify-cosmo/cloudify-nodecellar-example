#########
# Copyright (c) 2014 GigaSpaces Technologies Ltd. All rights reserved
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
#  * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  * See the License for the specific language governing permissions and
#  * limitations under the License.

import sys
import json
import os
import contextlib
import datetime
import traceback
import time

from influxdb.influxdb08 import InfluxDBClient

from cloudify_rest_client import CloudifyClient
from cloudify_rest_client.executions import Execution


def validate_cooldown():
    with state() as s:
        now = time.time()
        then = s['cooldown_timestamp']
        delta = now - then
        if delta < 120:
            log('Cooldown in progress...Not performing any actions. Time '
                'left: {0} seconds'.format(120 - delta))
            exit(0)


def validate_scaling():

    with state() as s:
        current_execution_id = s['current_execution_id']

    if current_execution_id:

        # execution is still in progress
        log('Scaling is in progress...Not performing any actions')

        cloudify = CloudifyClient('localhost')
        execution = cloudify.executions.get(current_execution_id)
        if execution.status in Execution.END_STATES:
            # the execution ended not long ago,
            # update cooldown timestamp and current execution id
            log('Scaling process has ended. Updating cooldown and '
                'execution state.')
            with state() as s:
                s['cooldown_timestamp'] = time.time()
                s['current_execution_id'] = None

        exit(0)


def log(message):
    with open(log_file, 'a') as f:
        timestamp = datetime.datetime.now().isoformat()
        f.write('[{0}] - {1}'.format(timestamp, message))
        f.write(os.linesep)
    print message


@contextlib.contextmanager
def state():
    with open(state_file, 'r') as f:
        content = f.read()
        if not content:
            # initial state
            _state = {
                'cooldown_timestamp': 0,
                'current_execution_id': None
            }
        else:
            _state = json.loads(content)
        yield _state
    with open(state_file, 'w') as f:
        json.dump(_state, f, indent=2)
        f.write(os.linesep)


class NodeScaler(object):

    def __init__(self, node_name):
        self.node_name = node_name
        self.cloudify = CloudifyClient('localhost')
        self.influx = InfluxDBClient(host='localhost',
                                     port=8086,
                                     database='cloudify')

    def log(self, message):
        log('<{0}> - {1}'.format(self.node_name, message))

    def maybe_scale(self):

        instances = self.cloudify.node_instances.list(
            deployment_id, self.node_name)

        for instance in instances:
            value = self._get_instance_reading(instance.id)
            if value > threshold:
                self.log('Detected a threshold breach for instance: {'
                         '0}. [value={1} > threshold={2}]'
                         .format(instance.id, value, threshold))
                self.log('Attempting to scale node')
                execution_id = self.cloudify.executions.start(
                    deployment_id, 'scale', {
                        'node_id': self.node_name,
                        'delta': 1
                    }).id
                with state() as s:
                    s['current_execution_id'] = execution_id
                self.log('Successfully started scaling process: '
                         '{0}'.format(execution_id))
                exit(0)

    def _get_instance_reading(self, instance_id):
        query = 'SELECT MEAN(value) FROM /{0}\.{1}\.{' \
                '2}\.{3}/ GROUP BY time(10s) WHERE  time > ' \
                'now() - 40s'.format(deployment_id, self.node_name,
                                     instance_id, service_name)
        result = self.influx.query(query)
        return result


def scale():

    # check if there is a scaling process already running
    validate_scaling()

    # check if we are passed the cooldown period
    validate_cooldown()

    # now we can try and scale some nodes
    for node_name in nodes_to_scale:
        scaler = NodeScaler(node_name)
        scaler.maybe_scale()

    exit(0)

if __name__ == '__main__':

    # parse arguments
    nodes_to_scale = json.loads(sys.argv[1].replace("'", '"'))
    deployment_id = sys.argv[2]
    service_name = sys.argv[3]
    threshold = int(sys.argv[4])

    # configure files
    log_file = os.path.expanduser('~/{0}-scaler.log'.format(deployment_id))
    state_file = os.path.expanduser('~/{0}-scaler.state'.format(deployment_id))
    if not os.path.exists(state_file):
        # create state file if doesn't exist
        open(state_file, 'w').close()

    # handle exceptions
    def new_exception_hook(exctype, value, tb):
        log('Unhandled exception: {0}\n'.format(exctype))
        log('Value: {0}\n'.format(value))
        traceback.print_tb(tb, file=log_file)
        raise exctype, value, tb

    sys.excepthook = new_exception_hook

    # execute scale logic
    scale()
