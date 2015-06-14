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
        f.write('[{0}] {1}'.format(timestamp, message))
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


def maybe_scale(threshold):

    # check if there is a scaling process already running
    validate_scaling()

    # check if we are passed the cooldown period
    validate_cooldown()

    # now we can try and scale

    cloudify = CloudifyClient('localhost')
    influx = InfluxDBClient(host='localhost',
                            port=8086,
                            database='cloudify')

    instances = cloudify.node_instances.list(
        deployment_id, mongo_node_name)

    threshold = threshold * len(instances)

    def _get_sum_mongo_connections(instance_id):
        query = 'select sum(value) from /{0}\.{1}\.{' \
                '2}\.mongo_connections_totalCreated/' \
            .format(deployment_id, mongo_node_name,
                    instance_id)
        result = influx.query(query)
        return result[0]['points'][0][1]

    for instance in instances:
        value = _get_sum_mongo_connections(instance.id)
        log('Querying total number of connections for '
            'instance {0} --> {1}'.format(instance.id, value))
        if value > threshold:
            log('Detected a threshold breach for mongo instance: {'
                '0}. [value={1} > threshold={2}]'
                .format(instance.id, value, threshold))
            log('Attempting to scale nodejs_host node')
            execution_id = cloudify.executions.start(
                deployment_id, 'scale', {
                    'node_id': nodejs_host_node_name,
                    'delta': 1
                }).id
            with state() as s:
                s['current_execution_id'] = execution_id
            log('Successfully started scaling process: '
                '{0}'.format(execution_id))
            exit(0)

    exit(0)

if __name__ == '__main__':

    # parse arguments
    nodejs_host_node_name = sys.argv[1]
    mongo_node_name = sys.argv[2]
    deployment_id = sys.argv[3]
    threshold = int(sys.argv[4])

    temp_directory = '/tmp'

    # configure files
    log_file = '{0}/{1}-scaler.log'.format(temp_directory, deployment_id)
    state_file = '{0}/{1}-scaler.state'.format(temp_directory, deployment_id)

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
    maybe_scale(threshold)
