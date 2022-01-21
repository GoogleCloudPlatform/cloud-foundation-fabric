# Data Platform

This module implement an opinionated Data Platform (DP) that create and set up projects (and related resources) to be used for your workloads.

# Design overview and choices #TODO
Diagram and introduction
## Project structure
The DP is designed to rely on several projects, one prj per data stage. This is done to better separate different
stages of the data journey and rely on project level roles.

The following projects will be created:
* **Landing** This Project is intended to store data temporarily. Data are pushed to Cloud Storage, BigQuery or Cloud PubSub. Resource configured with 3 months lifecycle policy.

* **Load** This Project is intended to load data from `landing` to `data lake`. Load is made with minimal to zero transformation logic (mainly `cast`). Anonymization/tokenization/DLP PII data can be applied at this stage or a later stage.

* **Data Lake** This project is intended to store your data. It reppresents where data will be persisted within 3 Layers. These layers reppresent different stages where data is processed and progressivly refined
  * **L0 - Raw data** Structured Data, stored in adeguate format: structured data stored in bigquery, unstructured data stored on Cloud Storage with additional metadata stored in Bigquery (for example pictures stored in Cloud Storage and analysis of the picture for Cloud Vision API stored in Bigquery). 
  * **L1 - Cleansed, aggregated and standardized data**
  * **L2 - Curated layer**
  * **Experimental** Store temporary tables that Data Analyst may use to perform R&D on data available on other Data Lake layers
* **Orchestration** This project is inteded to host Cloud Composer. Cloud Composer will orchestrate all tasks to move your data on its journey.
* **Transformation** This project is intended to host resources to move data from one layer of the Data Lake to the other. We strongly suggest to rely on BigQuery engine to perform transformation. If Bigquery do not have the feature needed to perform your transformation you suggest to use Clud Dataflow.
* **Exposure** This project is intended to host resources to expose your data. To expose Bigquery data, we strongly suggest to rely on Authorized views. Other resources may better fit on particular data access pattern, example: Cloud SQL may be needed if you need to expose data with low latency, BigTable may be needed on use case where you need low latency to access data.

## Roles
Roles will be granted at Project level.
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
 #TODO Column level access on BQ
 #TODO DataCatalog
 #TODO DLP
 #TODO DataLake layers: Tables, views and Authorized views
 #TODO ShareVPC Role: roles/composer.sharedVpcAgent, roles/container.hostServiceAgentUser
 #TODO Composer require "Require OS Login" not enforced