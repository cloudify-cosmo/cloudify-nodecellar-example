import fabric
from cloudify import ctx

def _run(command):
    ctx.logger.info(command)
    out = fabric.api.run(command)
    ctx.logger.info(out)


def install(config):
    ctx.logger.info("Config: " + str(config))
    script = []
    script.append("""
curl -sL https://deb.nodesource.com/setup | sudo bash -
sudo apt-get update 2>&1
sudo apt-get install nodejs make g++ wget -q -y 2>&1
    """)
    _run("\n".join(script))
