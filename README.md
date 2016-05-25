Cloudify Node Cellar Example
============================

[![Circle CI status](https://circleci.com/gh/cloudify-cosmo/cloudify-nodecellar-example/tree/master.svg?&style=shield)](https://circleci.com/gh/cloudify-cosmo/cloudify-nodecellar-example/tree/master)
![Node Cellar local tested](http://img.shields.io/badge/nodecellar--local-tested-green.svg)
![Node Cellar simple manually tested](http://img.shields.io/badge/nodecellar--simple-manually--tested-yellow.svg)
![Node Cellar host pool tested](http://img.shields.io/badge/nodecellar--host--pool-tested-green.svg)
![Node Cellar OpenStack tested](http://img.shields.io/badge/nodecellar--openstack-tested-green.svg)
![Node Cellar OpenStack HAProxy tested](http://img.shields.io/badge/nodecellar--openstack--haproxy--net-tested-green.svg)
![Node Cellar OpenStack Nova tested](http://img.shields.io/badge/nodecellar--openstack--nova--net-tested-green.svg)
![Node Cellar CloudStack manually tested](http://img.shields.io/badge/nodecellar--cloudstack-manually--tested-yellow.svg)
![Node Cellar EC2 tested](http://img.shields.io/badge/nodecellar--aws--ec2-tested-green.svg)
![Node Cellar vCloud tested](http://img.shields.io/badge/nodecellar--vcloud-tested-green.svg)
![Node Cellar vSphere tested](http://img.shields.io/badge/nodecellar--vcloud-tested-green.svg)
![Node Cellar SoftLayer tested](http://img.shields.io/badge/nodecellar--softlayer-tested-green.svg)

This repository contains blueprints for installing
[Node Cellar](http://coenraets.org/blog/2012/10/nodecellar-sample-application-with-backbone-js-twitter-bootstrap-node-js-express-and-mongodb/)
on several cloud and other environments. It is a simple two-node deployment that is useful for learning how to use [Cloudify](http://docs.getcloudify.org/3.4.0/intro/what-is-cloudify/) and how to write blueprints, for testing Cloudify installations, and for testing cloud environments. 

In addition to installing the application's resources and dependencies, the blueprints will also install a Cloudify agent that reports statistics and allows a Cloudify Manager to better control the hosts. (The exception is the local blueprint, which does not install the agent.)

## Quick start using the local blueprint

First [install the Cloudify CLI](http://docs.getcloudify.org/3.4.0/intro/installation/).

[The local blueprint](local-blueprint.yaml) allows you to install Node Cellar on your local host. (Note that it does _not_ require nor use a Cloudify Manager.)

### Step 1: Initialize

First, let's initialize your working directory to work with the given blueprint. 

    cfy local init -p local-blueprint.yaml

Now, you can run any type of workflow using this blueprint.

### Step 2: Install

Let's run the `install` workflow:

    cfy local execute -w install

This command will install all the application components on you local machine. (Everything will be safely installed installed under the `tmp` directory.) Once it's done, you should be able to browse to [http://localhost:8080](http://localhost:8080) and see the application.

### Step 3: Uninstall

To uninstall the application we run the `uninstall` workflow:

    cfy local execute -w uninstall

## Cloud blueprints

For pre-provisioned hosts:

- [Simple](simple-blueprint.yaml) - deploy on arbitrary hosts with known IP addresses
- [Host pool](host-pool-blueprint.yaml) - deploy on arbitrary hosts with IP addresses managed by a [Host Pool Service](https://github.com/cloudify-cosmo/cloudify-host-pool-service); see also the [the plugin documentation](http://docs.getcloudify.org/3.4.0/plugins/host-pool/)

With provisioning of hosts:

- [OpenStack](openstack-blueprint.yaml)
- [OpenStack HAProxy](openstack-haproxy-blueprint.yaml)
- [OpenStack Nova](openstack-nova-net-blueprint.yaml)
- [Apache CloudStack](cloudstack-blueprint.yaml)
- [Amazon EC2](aws-ec2-blueprint.yaml)
- [VMWare vCloud](vcloud-blueprint.yaml)
- [VMWare vSphere](vsphere-blueprint.yaml)
- [IBM SoftLayer](softlayer-blueprint.yaml)

The cloud blueprints require access to a [Cloudify Manager](http://docs.getcloudify.org/3.4.0/intro/cloudify-manager/) instance. You can get one by deploying one of the [ready-to-run images](http://docs.getcloudify.org/3.4.0/manager/manager-images/) or [bootstrapping your own](http://docs.getcloudify.org/3.4.0/manager/bootstrapping/), including on a [local virtual machine](http://docs.getcloudify.org/3.4.0/manager/getting-started/).

These blueprints assume a topology of two hosts:

- A Node.js server, running the JavaScript application
- A MongoDB instance

(The exception is the OpenStack HAProxy blueprint, which adds a third host for HAProxy.)

### Step 1: Connect to the Cloudify Manager

Tell the CLI to use the Manager:

    cfy use -t <Manager IP address>

### Step 2: Upload the blueprint

    cfy blueprints upload -b <choose a blueprint ID> -p <blueprint filename.yaml>

### Step 3: Create a deployment

Every one of these blueprints has inputs, which can be populated for a deployment using input files. Templates for such input files are located inside the `inputs` directory. Note that these templates only contain the _mandatory_ inputs, those for which the blueprint does not define a default value. Look inside the blueprints for documentation about additional inputs.

    cp inputs/<inputs filename.yaml.template> <inputs filename.yaml>

After you filled the input file corresponding to your blueprint, create the deployment:

    cfy deployments create -b <blueprint ID used above> -d <choose a deployment ID> -i <inputs filename.yaml>

### Step 4: Install

Once the deployment is created, we can start running workflows:

    cfy executions start -w install -d <deployment ID used above>

This `install` workflow will create all the resources and run all the lifecycles tasks needed for deployment in the environment, including:

- Virtual machines
- Floating IP addresses
- Security groups

### Step 5: Verify installation

Once the workflow execution is complete, we can view the application endpoint by running:

    cfy deployments outputs -d <deployment ID>

One of the outputs should be the application's URL. Browse it to see Node Cellar in action!

### Step 6: Uninstall

Now lets run the `uninstall` workflow, which will uninstall the application as well as the resources:

    cfy executions start -w uninstall -d <deployment ID>

### Step 7: Delete the deployment

It's best to delete deployments we are no longer using, since they take up space on the management machine:

    cfy deployments delete -d <deployment_id>

### Step 8: Tear down the manager

If you have no further use for your Cloudify Manager, you can tear it down (together with the resources created by the bootstrap process) by running:

    cfy teardown -f

## What's next?

Visit the Cloudify community website at [getcloudify.org](http://getcloudify.org) for more guides and tutorials.

