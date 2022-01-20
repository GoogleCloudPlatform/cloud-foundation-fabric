# Data Platform

This module implement an opinionated Data Platform (DP) that create and set up projects (and related resources) to be used for your workloads.

# Design overview and choices #TODO
Diagram and introduction
## Project structure #TODO
One prj per data stage.

## Roles
Assigned at PRJ level
## Service accounts #TODO
- Service account with minimal roles
## Groups #TODO
Describe here groups to configure and their role:
- Data Eng
- Data Analyst
## VPC design #TODO
Internal: one VPC per prj, where neede (lod, trf, )
## IP ranges, subnetting #TODO
List subnets and ranges.
How to rely on Shared-VPC

## Resource naming convention #TODO

## Encryption
We suggest a centralized approach to Keys management, to let the Security team be the only team that can access encryption material. Keyrings and Keys belongs to a project external to the DP. 

![Centralized Cloud KMS high level diagram](diagram.png "GCS to Biquery High-level diagram")

To configure the use of Cloud KMS on resources you have to specify key URL on the 'service_encryption_keys'. Key location should match the resource location. Example:

```
service_encryption_keys = {
    bq       = "KEY_URL_MULTIREGIONAL"
    composer = "KEY_URL_REGIONAL"
    dataflow = "KEY_URL_REGIONAL"
    storage  = "KEY_URL_MULTIREGIONAL"
    pubsub   = "KEY_URL_MULTIREGIONAL"
```

We consider this step optional, it depend on customer policy and security best practices.

# How to run this script #TODO
The Data Prlatform is meant to be executed by a Service Account (or a regular user) having this minial set of permission:
* **Org level**
  * TODO
* **Cloud KMS Keys** (if Cloud KMS keys are configured)
  * TODO
* **Network** (if DP needs to rely on an existing Shared-VPC)
  * TODO

# Variable configuration #TODO

# Customizations #TODO
Add internal KMS?
Parallel workstream

# RAW notes, TO BE delete
 - GCS and BQ regional
 - KMS: Regional keyring, one key per product
 - Composer require "Require OS Login" not enforced
 - Groups: gcp-data-scientists, gcp-data-engineers

 #TODO KMS: support key per product
 #TODO Write README
 #TODO Run a working test
 #TODO Write a working e2e test
 #TODO Column level access on BQ
 #TODO DataCatalog
 #TODO DLP
 #TODO DataLake layers: Tables, views and Authorized views
 #TODO ShareVPC Role: roles/composer.sharedVpcAgent, roles/container.hostServiceAgentUser
 #TODO Composer require "Require OS Login" not enforced