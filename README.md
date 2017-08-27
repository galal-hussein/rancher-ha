# Terraform Rancher HA

## Overview

This Terraform script will deploy Rancher HA setup on AWS, and it uses S3 as a backend for remote state files.

## Description

The script in `rancher-ha` directory uses the [official Terraform modules](https://github.com/rancher/terraform-modules) to create AWS resources including:

- Management and Bastion secuirty groups.
- RDS database.
- Elastic Load Balancer.
- Autoscaling Group with Launch Configuration.

### Modules structure

The script will deploy all modules in three separate steps, the modules are:

1. network
2. database
3. management-cluster

#### Network Module

Network module will create the network security groups and certificate needed for accessing the ELB, this module will define also the vpc and subnets that will be used to deploy the rest of the resources, note that this module **doesn't** create new vpc or subnets as its intended for frequent uses, you can also choose to deploy the resources in the **default** vpc, availability zones, and subnets if you set `aws_use_defaults` to true.

#### Database Module

The Database Module will only deploy the RDS MySQL database with the default settings from the [Terraform modules](https://github.com/rancher/terraform-modules), currently it doesn't use Multi-AZ or snapshot but its scheduled to be added later.

#### Management Cluster

This module will deploy the rest of the components for the HA setup, it will set up an Autoscaling group for the Rancher servers, the module supports running different operating system using the `aws_ami` resource which can search for the AMI name and return its id, the following are the tested operating systems that works with the setup:

|     OS Name     |    Variable Value    |
|:---------------:|:--------------------:|
| RancherOS 1.0.4 | rancheros-v1.0.4-hvm |
| RancherOS 1.0.3 | rancheros-v1.0.3-hvm |
|   Ubuntu 16.04  |  ubuntu-xenial-16.04 |
|   Ubuntu 14.04  |  ubuntu-trusty-14.04 |
|     RHEL 7.4    |       rhel-7.4       |
|     RHEL 7.3    |       rhel-7.3       |
|     RHEL 7.2    |       RHEL 7.2       |

The variable value is the value that represent `operating_system`, the script will automatically install Docker specified by docker version `docker_version` variable, and will deploy the Rancher server with version specified also by `rancher_version` variable.

### S3 Remote State

The Terraform code uses S3 as a backend for remote state storage, this allows the script to be used by a team on a shared AWS infrastructure, the code takes a value of s3 bucket name to store these state files for each of three modules, and can be pulled later for stack teardown or any changes.

## Usage

To deploy the stack start by defining the terraform variables for each module and create this module separately by the following order:

### Perquisites

1. Clone the terraform official modules first:
```
git clone https://github.com/rancher/terraform-modules.git
```
2. Create a `files` directory and add certificates to it:
```
mkdir -p files
echo -e "${RANCHER_SSL_CERT}" > files/crt.pem
echo -e "${RANCHER_SSL_KEY}" > files/key.pem
echo -e "${RANCHER_SSL_CHAIN}" > files/chain.pem
chmod 600 files/*
```
3. Create the common `main.tfvars` variable files and define common variables:

|    Variable    |              Description              |
|:--------------:|:-------------------------------------:|
| aws_access_key |             AWS Access Key            |
| aws_secret_key |             AWS Secret Key            |
|   aws_region   |           AWS default region          |
|  aws_env_name  |               Stack name              |
|  aws_s3_bucket | S3 bucket name for remote state files |

4. Export few environment variables:
```
export AWS_S3_BUCKET=<s3-bucket-name>
export AWS_ENV_NAME=<aws-env-name>
export AWS_DEFAULT_REGION=<aws-region>
```
### Network Deployment

1. Change directory to the network module
```
cd network/
```
2. Initialize the terraform with s3 backend:
```
make SHELL='sh -x' init-s3
```
3. Create the network `network.tfvars` variables that includes:

|     Variable     |                                                          Description                                                         |
|:----------------:|:----------------------------------------------------------------------------------------------------------------------------:|
| server_cert_path |                                 Certificate that will be used for the SSL termination of ELB                                 |
|  server_key_path |                               Certificate key that will be used for the SSL termination of ELB                               |
|   ca_chain_path  |                              Certificate chain that will be used for the SSL termination of ELB                              |
| aws_use_defaults | Use default VPC, Subnet for deployin all the network resources if defined then there is no need to define the next variables |
|  aws_subnet_azs  |                                      AWS availability zones for deploying the resources                                      |
|    aws_vpc_id    |                                     The vpc id that will be used for deploying resources                                     |
| aws_subnet_cidrs |                            comma separated subnet cidrs that will be used for deploying resources                            |
|  aws_subnet_ids  |                             comma separated subnet ids that will be used for deploying resources                             |

4. Plan the terraform code to an output file:
```
make plan-output
```
5. Apply the plan to deploy network module:
```
PLAN=`ls *.plan` make apply-plan
```
### Database Deployment

1. Change directory to the database module
```
cd database/
```
2. Initialize the terraform with s3 backend:
```
make SHELL='sh -x' init-s3
```
3. Create the database `database.tfvars` variables that includes:

|        Variable        |                Description                |
|:----------------------:|:-----------------------------------------:|
|    database_password   | The database password for the cattle user |
| aws_rds_instance_class |      Instance class for RDS instance      |

*There are a lot of enhancement yet left to be done on this particular module to increase the options and features.*

4. Plan the terraform code to an output file:
```
make plan-output
```
5. Apply the plan to deploy database module:
```
PLAN=`ls *.plan` make apply-plan
```

### Management Cluster Deployment

1. Change directory to the management-cluster module
```
cd management-cluster/
```
2. Initialize the terraform with s3 backend:
```
make SHELL='sh -x' init-s3
```
3. Create the `management-cluster.tfvars` variables that includes:

|      Variable      |                       Description                      |
|:------------------:|:------------------------------------------------------:|
|   rancher_version  |                 Rancher server version                 |
|  operating_system  |     Operating system for the Rancher servers' hosts    |
|  aws_instance_type |                 The ASG instance types                 |
|     domain_name    |      The domain name that will be added to Route53     |
|   docker_version   |        Docker version installed on the machines        |
|    rhel_selinux    |    Whether or not to enable SELinux on RHEL machines   |
| rhel_docker_native |      Whether or not use RHEL's own Docker package      |
|      key_name      | The aws key name that will be deployed on the machines |
|       zone_id      |                   The route53 zone id                  |
|   scale_min_size   |                Minimum scale of the ASG                |
|   scale_max_size   |                Maximum scale of the ASG                |
| scale_desired_size |                Desired scale of the ASG                |

4. Plan the terraform code to an output file:
```
make plan-output
```
5. Apply the plan to deploy management-cluster module:
```
PLAN=`ls *.plan` make apply-plan
```

## Jenkins Usage

The repository can be added as a pipeline job to simplify the creation and deletion of the stacks, use `Jenkinsfile` as a pipeline path for adding a job to deploy this stack, you will have to only define a set of environment variables defined in `scripts/` to be able to use the job.

The Jenkinsfile will automatically build a docker image that has terraform and some dependencies and will deploy each module separately as described above.

## TODO

- Enhance the Database module to include more options.
- Extra disk to RHEL nodes to enable LVM docker thinpools.
- Option for local state files.
- VPC, private, and public subnet creation.
- Kubernetes Environment Deployment.
- Add Rancher agents automatically.
