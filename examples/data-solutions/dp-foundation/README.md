# Data Platform

This module implement an opinionated Data Platform (DP) Architecture that create and set up projects (and related resources) to be used for your data workloads.

# Design overview and choices #TODO
This is the Data Platform architecture we are going to deploy.

![Data Platform Architecture overview](./images/overview_diagram.png "Data Platform Architecture overview")

## Project structure
The DP is designed to rely on several projects, one prj per data stage. This is done to better separate different stages of the data journey and rely on project level roles.

The following projects will be created:
* **Landing** This Project is intended to store data temporarily. Data are pushed to Cloud Storage, BigQuery or Cloud PubSub. Resource configured with 3 months lifecycle policy.

* **Load** This Project is intended to load data from `landing` to `data lake`. Load is made with minimal to zero transformation logic (mainly `cast`). Anonymization/tokenization/DLP PII data can be applied at this stage or in the transofmation stage depending on your requirements.

* **Data Lake** Those projects is intended to store your data. It reppresents where data will be persisted within 3 Layers. These layers reppresent different stages where data is processed and progressivly refined
  * **L0 - Raw data** Structured Data, stored in adeguate format: structured data stored in bigquery, unstructured data stored on Cloud Storage with additional metadata stored in Bigquery (for example pictures stored in Cloud Storage and analysis of the picture for Cloud Vision API stored in Bigquery). 
  * **L1 - Cleansed, aggregated and standardized data**
  * **L2 - Curated layer**
  * **Experimental** Store temporary tables that Data Analyst may use to perform R&D on data available on other Data Lake layers
* **Orchestration** This project is inteded to host Cloud Composer. Cloud Composer will orchestrate all tasks to move your data on its journey.
* **Transformation** This project is intended to host resources to move data from one layer of the Data Lake to the other. We strongly suggest to rely on BigQuery engine to perform transformation. If Bigquery do not have the feature needed to perform your transformation you suggest to use Clud Dataflow.
* **Exposure** This project is intended to host resources to expose your data. To expose Bigquery data, we strongly suggest to rely on Authorized views. Other resources may better fit on particular data access pattern, example: Cloud SQL may be needed if you need to expose data with low latency, BigTable may be needed on use case where you need low latency to access data.

## Roles
We assigned roles on resources at Project level assigning the appropriate role to groups. We recommend not adding human users directly to the resource-access groups with IAM permissions to access data.

The only exception is for BigQuery dataset. We let you configure IAM at dataset level to host in the same infrastructure dataset that need access level segregation.

## Service accounts #TODO
Service Account creation follow the following principals:
- Each service account perform a single task aving access to the minimun number of resources (example: the Cloud Dataflow Service Account has access to the Landing project and to the Data Lake L0 project)
- Each Service Account has least privilage on each project.

### Service Account Keys
Service Account Keys (SAK) are out of scope for this example. The example implemented rely on Service Account Impersonification avoiding the creation of SAK.

The use of SAK within a data pipeline incurs several security risks, as these are physical credentials, matched to an automated system, that can be distributed without oversight or control. 

Whilst necessary in some scenarios, such as programmatic access from on-premise or alternative clouds, we recommend identify a structured process to mitigate risks associated with the use of service account keys.


## Groups #TODO
As default groups, we identified the following actors:
- *Data Engineers*: the group that handle and run the Data Hub. The group has Read access to all resources to be able to troubleshoot possible issue with the pipeline. The team has also the ability to impersonate all service accounts. Default value: `gcp-data-engineers@DOMAIN.COM`. 
- *Data Analyst*: the group that perform analysis on the dataset. The group has Read access to the Data Lake L2 project and Bigquery READ/WRITE access to the `experimental` project. Default value: `gcp-data-analyst@DOMAIN.COM`
- *Data Security*: the project that handle security features related to the Data Hub. Default name: `gcp-data-security@DOMAIN.com`
## VPC design #TODO
The DP except as input an existing Shared-VPC to run resources. You can configure subsets for DP resource specifying the link to the subnet in the `` variable. You may want to configure a shared-VPC to run your resources in the case your pipelines may need to reach on-premise resources.

If no VPC configuration, the project will create a VPC on each project that require a VPC: *laod* project, *trasformation* project and *orchestration* project.
## IP ranges, subnetting #TODO
To run your DP resources you need the following ranges:
- Load project VPC for Dataflow. Range: '/24'.
- Transformation VPC for Dataflow. Range: '/24'.
- Orchestration VPC for Cloud Composer:
  - Cloud SQL. Range: '/24'
  - GKE Master. Range: '/28'
  - Web Server: Range: '/28'
  - Secondary ip ranges. Pods range: '/22', Services range: '/24'  

## Resource naming convention #TODO

## Encryption
We suggest a centralized approach to Keys management, to let the Security team be the only team that can access encryption material. Keyrings and Keys belongs to a project external to the DP. 

![Centralized Cloud KMS high level diagram](./images/kms_diagram.png "Centralized Cloud KMS high level diagram")

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

# Data Anonymization
We suggest the use of Cloud Data Loss Prevention to identify/mask/tokenize your confidential data. The implementation of the Data Loss Prevention strategy is out of scope for this example. We enable the service in 2 different projects to let you implement the DLP strategy. We expect you will use DLP templates in one of the following way:
- During the ingestion phase, from Dataflow
- During the transformation phase, from BigQuery or Dataflow

We implemented a centralized model for Data Loss Prevention material. Templates will be stored in the security project:

![Centralized Cloud DLP high level diagram](./images/dlp_diagram.png "Centralized Cloud DLP high level diagram")

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
 - Groups: gcp-data-scientists, gcp-data-engineers, gcp-data-security

 #TODO KMS: support key per product
 #TODO Write README
 #TODO Column level access on BQ
 #TODO DataCatalog
 #TODO DLP
 #TODO DataLake layers: Tables, views and Authorized views
 #TODO ShareVPC Role: roles/composer.sharedVpcAgent, roles/container.hostServiceAgentUser
 #TODO Composer require "Require OS Login" not enforced