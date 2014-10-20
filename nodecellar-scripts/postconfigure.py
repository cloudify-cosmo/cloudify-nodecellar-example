
from subprocess import call

from cloudify import ctx


"""
Gets the mongo ip address and port and stores them in a file to be sourced by the
nodecellar startup script
"""

mongo_ip_address = ctx.target.instance.runtime_properties['ip_address']
mongo_port = ctx.target.instance.runtime_properties['port']

ctx.logger.info('Mongo IP address is {0} and port is {1}'.format(mongo_ip_address, mongo_port))

env_file_path = ctx.source.node.properties['env_file_path'] or '/tmp/{0}/mongo_host_and_port.sh'.format(ctx.execution_id)

ctx.logger.info('Writing file {0}'.format(env_file_path))

with open(env_file_path, 'w') as env_file:
    env_file.write('export MONGO_PORT={0}\n'.format(mongo_port))
    env_file.write('export MONGO_HOST={0}\n'.format(mongo_ip_address))

call(['chmod', '+x', env_file_path])
