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

The first thing you'll need to do is
[install the Cloudify CLI](http://getcloudify.org/guide/3.1/installation-cli.html).
<br>
This will let you run the various blueprints.

**Note: <br>Documentation about the blueprints content is located inside the blueprint files themselves.
<br>Presented here are only instructions on how to RUN the blueprints using the Cloudify CLI.**
<br><br>
**From now on, all commands will assume that the working directory is the root of this repository.**

## Local Blueprint

[This blueprint](local-blueprint.yaml) allows you to install the nodecellar application on your local machine. <br>
Let see how this is done:

### Step 1: Initialize

`cfy local init -p local-blueprint.yaml` <br>

This command (as the name suggests) initializes your working directory to work with the given blueprint.
Now, you can run any type of workflows on this blueprint. <br>

### Step 2: Install

Lets run the `install` workflow: <br>

`cfy local execute -w install`

This command will install all the application components on you local machine.
(don't worry, its all installed under the `tmp` directory)<br>
Once its done, you should be able to browse to [http://localhost:8080](http://localhost:8080) and see the application.
<br>


### Step 3: Uninstall

To uninstall the application we run the `uninstall` workflow: <br>

`cfy local execute -w uninstall`

## All other blueprints

- [Openstack Blueprint](openstack-blueprint.yaml)
- [Openstack Nova Net Blueprint](openstack-nova-net-blueprint.yaml)
- [EC2 Blueprint](ec2-blueprint.yaml)
- [Singlehost Blueprint](singlehost-blueprint.yaml)

All of these blueprints allow you to install the nodecellar application on different cloud environments.
Doing this requires first to bootstrap a Cloudify Manager.<br>

### Step 1: Bootstrapping

Please refer to [Bootstrapping Cloudify](http://getcloudify.org/guide/3.1/installation-bootstrapping.html) to setup your own Cloudify Manager.
<br><br>

Great, now that you have your very own Cloudify Manager, we can work with these blueprints.
<br>

### Step 2: Upload the blueprint

`cfy blueprints upload -b <choose_blueprint_id> -p <blueprint_filename>` <br>

### Step 3: Create a deployment

Every one of these blueprints have inputs, which can be populated for a deployment using the input files. <br>

`cfy deployments create -b <blueprint_id> -d <choose_deployment_id> -i inputs/<inputs_filename>`

### Step 4: Install

Once the deployment is created, we can start running workflows: <br>

`cfy executions start -w install -d <deployment_id>`

This process will create all the cloud resources needed for the application: <br>

- VM's
- Floating IP's
- Security Groups

and everything else that is needed and declared in the blueprint.<br>

### Step 5: Verify installation

Once the workflow execution is complete, we can view the application endpoint by running: <br>

`cfy deployments outputs -d <deployment_id>`

### Step 6: Uninstall

Now lets run the `uninstall` workflow. This will uninstall the application,
as well as delete all related resources. <br>

`cfy executions start -w uninstall -d <deployment_id>`

### Step 7: Delete the deployment

Its best to delete deployments we are no longer using, since they take up memory on the management machine.
We do this by running:

`cfy deployments delete -d <deployment_id>`

### Step 8: Tearing down the manager

If you have no further use for your Cloudify Manager, you can tear it (and all resources created by the bootstrap process)
by running:

`cfy teardown -f`

## What's Next

Visit us on the Cloudify community website at [getcloudify.org](http://getcloudify.org) for more guides and tutorials.

