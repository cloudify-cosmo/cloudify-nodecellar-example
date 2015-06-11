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
    script = []
    script.append("""
wget https://github.com/cloudify-cosmo/nodecellar/archive/master.tar.gz -c -v 2>&1
tar -xvf master.tar.gz
cd nodecellar-master && npm update
    """)
    # create service config
    service = _generate_service(config.get("mongo", "localhost"))
    script.append("rm -f /home/ubuntu/nodecellar.conf")
    for service_str in service:
        script.append('echo "' + service_str + '" >> /home/ubuntu/nodecellar.conf')
    # create init file
    script.append("""
sudo cp /home/ubuntu/nodecellar.conf /etc/init/nodecellar.conf
sudo chown root:root /etc/init/nodecellar.conf
# run service
sudo initctl stop nodecellar || echo "not started"
sudo initctl start nodecellar
    """)
    _run("\n".join(script))
