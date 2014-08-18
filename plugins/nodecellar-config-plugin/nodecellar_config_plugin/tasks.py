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
from cloudify.decorators import operation
from subprocess import call


@operation
def get_mongo_host_and_port(ctx, **kwargs):
    
    """
    Gets the mongo ip address and port and stores them in a file to be sourced by the 
    nodecellar startup script 
    """
    
    mongo_ip_address = ctx.related.runtime_properties['ip_address']
    mongo_port = ctx.related.runtime_properties['port']
    
    ctx.logger.info("Mongo IP address is {} and port is {}".format(mongo_ip_address, mongo_port))

    env_file_path = ctx.properties.get(
        "env_file_path",
        "/tmp/{0}/mongo_host_and_port.sh".format(ctx.execution_id))
    ctx.logger.info("Writing file {}".format(env_file_path))

    with open(env_file_path, 'w') as env_file:
        env_file.write("export MONGO_PORT={}\n".format(mongo_port))
        env_file.write("export MONGO_HOST={}\n".format(mongo_ip_address))

    call(["chmod", "+x", env_file_path])

