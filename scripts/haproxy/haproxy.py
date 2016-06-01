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

import tempfile
from contextlib import contextmanager

from jinja2 import Template

from cloudify_rest_client import exceptions as rest_exceptions
from cloudify import ctx
from cloudify.state import ctx_parameters as inputs
from cloudify import exceptions
from cloudify import utils


CONFIG_PATH = '/etc/haproxy/haproxy.cfg'
TEMPLATE_RESOURCE_NAME = 'resources/haproxy/haproxy.cfg.template'


def configure(subject=None):
    subject = subject or ctx

    ctx.logger.info('Configuring HAProxy.')
    template = Template(ctx.get_resource(TEMPLATE_RESOURCE_NAME))

    ctx.logger.debug('Building a dict object that will contain variables '
                     'to write to the Jinja2 template.')

    config = subject.node.properties.copy()
    config.update(dict(
        frontend_id=subject.node.name,
        backends=subject.instance.runtime_properties.get('backends', {})))

    ctx.logger.debug('Rendering the Jinja2 template to {0}.'.format(
            CONFIG_PATH))
    ctx.logger.debug('The config dict: {0}.'.format(config))

    with tempfile.NamedTemporaryFile(delete=False) as temp_config:
        temp_config.write(template.render(config))

    _run('sudo /usr/sbin/haproxy -f {0} -c'.format(temp_config.name),
         error_message='Failed to Configure')

    _run('sudo mv {0} {1}'.format(temp_config.name, CONFIG_PATH),
         error_message='Failed to write to {0}.'.format(CONFIG_PATH))


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
        configure(subject=ctx.target)
        _service('reload')
    except rest_exceptions.CloudifyClientError as e:
        if 'conflict' in str(e):
            # cannot 'return' in contextmanager
            ctx.operation.retry(
                message='Backends updated concurrently, retrying.',
                retry_after=1)
        else:
            raise


def start():
    _service('start')


def stop():
    _service('stop')


def _service(state):
    _run('sudo service haproxy {0}'.format(state),
         error_message='Failed setting state to {0}'.format(state))


def _run(command, error_message):
    runner = utils.LocalCommandRunner(logger=ctx.logger)
    try:
        runner.run(command)
    except exceptions.CommandExecutionException as e:
        raise exceptions.NonRecoverableError('{0}: {1}'.format(
                error_message, e))


def _main():
    invocation = inputs['invocation']
    function = invocation['function']
    args = invocation.get('args', [])
    kwargs = invocation.get('kwargs', {})
    globals()[function](*args, **kwargs)


if __name__ == '__main__':
    _main()
