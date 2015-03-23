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
from cloudify_rest_client.exceptions import CloudifyClientError


def cooldown_expired():
    with state() as s:
        now = time.time()
        then = s['cooldown_timestamp']
        delta = now - then
        if delta < 420:
            return False
    return True


def log(message):
    with open(log_file, 'a') as f:
        timestamp = datetime.datetime.now().isoformat()
        f.write('[{0}] - {1}'.format(timestamp, message))
        f.write(os.linesep)


@contextlib.contextmanager
def state():
    with open(state_file, 'w+') as f:
        f.seek(0, 0)
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
        f.write(json.dumps(_state))
        f.write(os.linesep)


class NodesHealer(object):

    def __init__(self, node_names):
        self.node_names = node_names
        self.cloudify = CloudifyClient('localhost')

    def heal(self):
        for node_name in self.node_names:
            healer = NodeHealer(node_name)
            healer.heal()

    def heal_is_in_progress(self):

        with state() as s:
            current_execution_id = s['current_execution_id']
            self.log('Retrieving current execution id: {0}'
                     .format(current_execution_id))

        if current_execution_id is None:
            # no execution running, nothing to do
            return False
        else:
            execution = self.cloudify.executions.get(current_execution_id)
            self.log('Retrieving current execution status: {0}'.format(
                execution.status))
            if execution.status in Execution.END_STATES:
                # the execution ended not long ago,
                # update cooldown timestamp and current execution id
                with state() as s:
                    s['cooldown_timestamp'] = time.time()
                    s['current_execution_id'] = None
                return False

            # execution is still in progress
            return True

    @staticmethod
    def log(message):
        log(message)


class NodeHealer(object):

    def __init__(self, node_name):
        self.node_name = node_name
        self.cloudify = CloudifyClient('localhost')

    def heal(self):

        instances = self.cloudify.node_instances.list(
            deployment_id, self.node_name)

        for instance in instances:

            healer = NodeInstanceHealer(self.node_name, instance.id)

            healer.log('Performing liveness detection')
            if healer.instance_is_alive():
                healer.log('Instance is still alive...')
            else:
                healer.log('Detected node instance failure')
                healer.log('Attempting to execute heal workflow')

                try:

                    healer.log('Attempting to heal')
                    execution_id = healer.heal_async()
                    with state() as s:
                        s['current_execution_id'] = execution_id
                    healer.log('Successfully started healing process: {'
                               '0}'.format(execution_id))

                except CloudifyClientError as e:
                    healer.log('Failed to start healing process: {0}'
                               .format(str(e)))


class NodeInstanceHealer(object):

    def __init__(self, node_name, instance_id):
        self.node_name = node_name
        self.instance_id = instance_id
        self.cloudify = CloudifyClient('localhost')
        self.influx = InfluxDBClient(host='localhost',
                                     port=8086,
                                     database='cloudify')

    def log(self, message):
        log('<{0}> - {1}'.format(self.instance_id, message))

    def instance_is_alive(self):

        query = 'SELECT MEAN(value) FROM /{0}\.{1}\.{' \
                '2}\.cpu_total_system/ GROUP BY time(10s) WHERE  time > ' \
                'now() - 40s'.format(deployment_id, self.node_name,
                                     self.instance_id)

        self.log('Querying InfluxDB : {0}'.format(query))
        result = self.influx.query(query)
        self.log('Query Result : {0}'.format(result))
        return bool(result)

    def heal_async(self):
        return self.cloudify.executions.start(
            deployment_id, 'heal', {'node_id': self.instance_id}).id


def heal():

    healer = NodesHealer(nodes_to_heal)

    # check if there is a healing process already running
    healer.log('Checking if healing is in progress')
    if healer.heal_is_in_progress():
        healer.log('Healing in progress...Not performing actions')
        exit(0)

    # check if we are passed the cooldown period
    healer.log('Checking if cooldown period has expired')
    if not cooldown_expired():
        healer.log('Cooldown in progress...Not performing actions')
        exit(0)

    # now we can try and heal some instances
    healer.heal()
    exit(0)

if __name__ == '__main__':

    # parse arguments
    nodes_to_heal = json.loads(sys.argv[1].replace("'", '"'))
    deployment_id = sys.argv[2]

    # configure files
    log_file = os.path.expanduser('~/{0}-healer.log'.format(deployment_id))
    state_file = os.path.expanduser('~/{0}-healer.state'.format(deployment_id))
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

    # execute heal logic
    heal()
