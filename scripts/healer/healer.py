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
import datetime
import os

from influxdb.influxdb08 import InfluxDBClient

from cloudify_rest_client import CloudifyClient
from cloudify_rest_client.executions import Execution
from cloudify_rest_client.exceptions import CloudifyClientError


def cooldown_expired():
    if os.path.isfile(cooldown_file):
        now = datetime.datetime.now()
        then = datetime.datetime.fromtimestamp(os.path.getmtime(
            cooldown_file))
        delta = now - then
        seconds = delta.total_seconds()
        if seconds < 420:
            return False
    return True


def log(message):
    with open(logfile, 'a') as f:
        timestamp = datetime.datetime.now().isoformat()
        f.write('[{0}] - {1}'.format(timestamp, message))
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

        current_execution_id = None
        if current_execution_id is None:
            # no execution running, nothing to do
            return False
        else:
            execution = self.cloudify.executions.get(current_execution_id)
            if execution.status in Execution.END_STATES:
                # the execution ended not long ago,
                # update cooldown timestamp
                os.utime(cooldown_file, None)
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
                    healer.log('Successfully started healing process: {'
                               '0}'.format(execution_id))

                    # update modified timestamp on the cooldown file to
                    # indicate cooldown starts now
                    os.utime(cooldown_file, None)

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
        self.log('Query Result : {0}'.format(query))
        return bool(result)

    def heal_async(self):
        return self.cloudify.executions.start(
            deployment_id, 'heal', {'node_id': self.instance_id}).id


def heal():

    healer = NodesHealer(nodes_to_heal)

    # check if there is a healing process already running
    if healer.heal_is_in_progress():
        healer.log('Healing in progress...')
        exit(0)

    # check if we are passed the cooldown period
    if not cooldown_expired():
        healer.log('Cooldown in progress...')
        exit(0)

    # now we can try and heal some instances
    healer.heal()
    exit(0)

if __name__ == '__main__':

    # parse arguments
    nodes_to_heal = json.loads(sys.argv[1].replace("'", '"'))
    deployment_id = sys.argv[2]

    # configure files
    logfile = os.path.expanduser('~/{0}-healer.log'.format(deployment_id))
    cooldown_file = os.path.expanduser('~/{0}-healer.cooldown'.format(
        deployment_id))

    # handle exceptions
    def new_exception_hook(exctype, value, traceback):
        log('Unhandled exception: {0}\n'.format(exctype))
        log('Value: {0}\n'.format(value))
        traceback.print_tb(traceback, file=logfile)
        exit(1)

    sys.excepthook = new_exception_hook

    # execute heal logic
    heal()
