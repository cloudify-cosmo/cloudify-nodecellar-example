import fabric
from cloudify import ctx

def _run(command):
    ctx.logger.info(command)
    out = fabric.api.run(command)
    ctx.logger.info(out)

def _generate_service(mongodb_host):
    return [
        "description 'nodecellar service'",
        "# used to be: start on startup",
        "# until we found some mounts were not ready yet while booting:",
        "start on started mountall",
        "stop on shutdown",
        "# Automatically Respawn:",
        "respawn",
        "respawn limit 99 5",
        "script",
        "    export HOME='/home/ubuntu'",
        "    export NODECELLAR_PORT=8080",
        "    export MONGO_PORT=27017",
        "    export MONGO_HOST=" + mongodb_host,
        "    exec /usr/bin/nodejs /home/ubuntu/nodecellar-master/server.js 2>&1 > /tmp/log",
        "end script"
    ]

def install(config):
    ctx.logger.info("Config: " + str(config))
    _run("sudo apt-get install python-software-properties -q -y 2>&1")
    _run("sudo apt-add-repository ppa:chris-lea/node.js -y 2>&1")
    _run("sudo apt-get update 2>&1")
    _run("sudo apt-get install nodejs make g++ wget -q -y 2>&1")
    _run("wget https://github.com/cloudify-cosmo/nodecellar/archive/master.tar.gz 2>&1")
    _run("tar -xvf master.tar.gz")
    _run("cd nodecellar-master && npm update")
    # create service config
    service = _generate_service(config.get("mongo", "localhost"))
    _run("rm -f /home/ubuntu/nodecellar.conf")
    for service_str in service:
        _run('echo "' + service_str + '" >> /home/ubuntu/nodecellar.conf')
    # create init file
    _run("sudo cp /home/ubuntu/nodecellar.conf /etc/init/nodecellar.conf")
    _run("sudo chown root:root /etc/init/nodecellar.conf")
    # run service
    _run('sudo initctl start nodecellar')


