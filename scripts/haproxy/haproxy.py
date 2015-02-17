###############################################################################
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
###############################################################################

import os
import subprocess
import tempfile
from contextlib import contextmanager

from jinja2 import Template

from cloudify_rest_client import exceptions as rest_exceptions
from cloudify import ctx
from cloudify.state import ctx_parameters as inputs
from cloudify.exceptions import NonRecoverableError


CONFIG_PATH = '/etc/haproxy/haproxy.cfg'
TEMPLATE_RESOURCE_NAME = 'resources/haproxy/haproxy.cfg.template'


def configure(initial=True, subject=None):
    subject = subject or ctx

    ctx.logger.info('Configuring HAProxy.')
    template = Template(ctx.get_resource(TEMPLATE_RESOURCE_NAME))

    ctx.logger.debug('Building a dict object that will contain variables '
                     'to write to the Jinja2 template.')

    config = subject.node.properties.copy()
    config.update(dict(
        frontend_id=subject.node.name,
        backends=subject.instance.runtime_properties.get('backends', {})))

    ctx.logger.debug('Rendering the Jinja2 template to {0}.'.format(CONFIG_PATH))
    ctx.logger.debug('The config dict: {0}.'.format(config))

    with tempfile.NamedTemporaryFile(delete=False) as temp_config:
        temp_config.write(template.render(config))

    _run(['sudo', 'mv', temp_config.name, CONFIG_PATH],
         log_message='Write validation: {0}.',
         error_message='Failed to write to {0}.'.format(CONFIG_PATH))

    _run(['sudo', '/usr/sbin/haproxy', '-f', CONFIG_PATH, '-c'],
         log_message='Config Validation: {0}',
         error_message='Failed to Configure')

    if initial:
        _run(['sudo', '/bin/sed', '-i', 's/ENABLED=0/ENABLED=1/', '/etc/default/haproxy'],
             log_message='Enable service: {0}',
             error_message='Failed enabling service')


def add_backend(port, maxconn, backend_address=None):
    with _backends_update() as backends:
        backends[ctx.source.instance.id] = {
            'address': backend_address or ctx.source.instance.host_ip,
            'port': port,
            'maxconn': maxconn
        }


def remove_backend():
    with _backends_update() as backends:
        backends.pop(ctx.source.instance.id, None)


@contextmanager
def _backends_update():
    backends = ctx.target.instance.runtime_properties.get('backends', {})
    yield backends
    ctx.target.instance.runtime_properties['backends'] = backends
    # being explict because errors in unlink are ignored and
    # not retried without being explicit.
    # also, this way, we make sure that configure/reload
    # are only called with a fully update configuration
    try:
        ctx.target.instance.update()
        configure(initial=False, subject=ctx.target)
        service('reload')
    except rest_exceptions.CloudifyClientError as e:
        if 'conflict' in str(e):
            # cannot 'return' in contextmanager
            ctx.operation.retry(
                message='Backends updated concurrently, retrying.',
                retry_after=1)
        else:
            raise

def service(state):
    _run(['sudo', 'service', 'haproxy', state],
         log_message='Setting service state to ' + state + ' :{0}',
         error_message='Failed setting state to {0}'.format(state))


def _run(command, log_message, error_message):
    p = subprocess.Popen(command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE)
    output = p.communicate()
    ctx.logger.debug(log_message.format(output))
    if p.returncode != 0:
        raise NonRecoverableError(error_message)


def _main():
    invocation = inputs['invocation']
    function = invocation['function']
    args = invocation.get('args', [])
    kwargs = invocation.get('kwargs', {})
    globals()[function](*args, **kwargs)


if __name__ == '__main__':
    _main()
