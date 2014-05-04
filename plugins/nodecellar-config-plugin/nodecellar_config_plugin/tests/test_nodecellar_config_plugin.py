########
# Copyright (c) 2014 GigaSpaces Technologies Ltd. All rights reserved
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# * See the License for the specific language governing permissions and
# * limitations under the License.

__author__ = 'uric'

from nodecellar_config_plugin.tasks import get_mongo_host_and_port
import unittest
import os
import os.path

# from cloudify.mocks import MockCloudifyContext

MockCloudifyContext = namedtuple('MockCloudifyContext', ['node_id', 'related'])
Related = namedtuple('Related', ['runtime_properties'])

class NodeCellarPluginTests(unittest.TestCase):

    def test_get_mongo_host_and_port(self):

        ctx = MockCloudifyContext(
            node_id='id',
            related=Related(
                runtime_properties={'ip_address' : 'localhost', 'port' : '28017'}
            )
        )

        get_mongo_host_and_port(ctx)

        self.assertTrue(os.path.isfile('set_mongo_env.sh'))

        with open("set_mongo_env.sh") as env_file:
            env_file_lines = env_file.readlines()
            for line in env_file_lines:
                self.assertTrue(line.startwith("export MONGO_"))

        os.remove('set_mongo_env.sh')

