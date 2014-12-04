# Cloudify Nodecellar Example

This repository contains several blueprints for installing the
[nodecellar](http://coenraets.org/blog/2012/10/nodecellar-sample-application-with-backbone-js-twitter-bootstrap-node-js-express-and-mongodb/)
application.<br>
Nodecellar example consists of:

- A Mongo Database
- A NodeJS Server
- A Javascript Application

Before you begin its recommended you familiarize yourself with
[Cloudify Terminology](http://getcloudify.org/guide/3.1/reference-terminology.html).

## Install the Cloudify CLI

The first thing you'll need to do is
[install the Cloudify CLI](http://getcloudify.org/guide/3.1/installation-cli.html).
<br>
This will let you run the various blueprints.

## Now we can start working with our blueprints

**Note: <br><br>Documentation about the blueprints content is located inside the blueprint files themselves.
<br>Presented here are only instructions on how to RUN the blueprints using the Cloudify CLI.**
<br><br>
**From now on, all commands will assume that the working directory is the root of this repository.**

### Local Blueprint

[This blueprint](local-blueprint.yaml) allows you to install the nodecellar application on your local machine. <br>
Let see how this is done:

`cfy local init -p local-blueprint.yaml` <br>

This command (as the name suggests) initializes your working directory to work with the given blueprint.
Now, you can run any type of workflows on this blueprint.
Lets run the `install` workflow: <br>

`cfy local execute -w install`

This command will install all the application components on you local machine.
(don't worry, its all installed under the `tmp` directory)<br>
Once its done, you should be able to browse to [http://localhost:8080](http://localhost:8080) and see the application.
<br>

To uninstall the application we run the `uninstall` workflows: <br>

`cfy local execute -w uninstall`

### All other blueprints

- [Openstack Blueprint](openstack-blueprint.yaml)
- [Openstack Nova Net Blueprint](openstack-nova-net-blueprint.yaml)
- [EC2 Blueprint](ec2-blueprint.yaml)
- [Singlehost Blueprint](singlehost-blueprint.yaml)

All of these blueprints allow you to install the nodecellar application on different cloud environments.
Doing this requires first to bootstrap a Cloudify Manager.<br>
Please refer to [Bootstrapping Cloudify](http://getcloudify.org/guide/3.1/installation-bootstrapping.html) to setup your own Cloudify Manager.
<br><br>
Great, now that you have your very own Cloudify Manager, we can install these blueprints.
<br>

```bash
cfy blueprints upload -b <choose_blueprint_id> -p <blueprint_filename>
cfy deployments create -b <blueprint_id> -d <choose_deployment_id> -i inputs/<inputs_filename>
```
