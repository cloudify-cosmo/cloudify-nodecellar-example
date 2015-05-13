import fabric
from cloudify import ctx

def _run(command):
    ctx.logger.info(command)
    out = fabric.api.run(command)
    ctx.logger.info(out)

def install_mongo(config):
    ctx.logger.info("Config: " + str(config))
    _run("""
sudo sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10 2>&1
echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.0.list 2>&1
sudo apt-get update 2>&1
sudo apt-get install -y mongodb-org 2>&1
# enable access from any ip
# by default access blocked to localhost
sudo sed "s/bind_ip = /#bind_ip = /g" -i /etc/mongod.conf
sudo initctl stop mongod
sudo initctl start mongod
    """)

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

def install_node_js(config):
    ctx.logger.info("Config: " + str(config))
    script = []
    script.append("""
sudo apt-get install python-software-properties -q -y 2>&1
sudo apt-add-repository ppa:chris-lea/node.js -y 2>&1
sudo apt-get update 2>&1
sudo apt-get install nodejs make g++ wget -q -y 2>&1
wget https://github.com/cloudify-cosmo/nodecellar/archive/master.tar.gz 2>&1
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
sudo initctl start nodecellar
    """)
    _run("\n".join(script))
