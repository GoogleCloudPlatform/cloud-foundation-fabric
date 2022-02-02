# Data Platform

This module implements an opinionated Data Platform (DP) Architecture that creates and setup projects (and related resources) to be used to create your DP.

The code is intentionally simple, as it's intended to provide a generic initial setup (Networking, Cloud Storage Buckets, BigQuery datasets, etc.), and then allow easy customizations to complete the implementation of the intended design.

The following diagram is a high-level reference of the resources created and managed here:

![Data Platform architecture overview](./images/overview_diagram.png "Data Platform architecture overview")

A demo pipeline is also part of this example: it can be built and run on top of the foundational infrastructure to quickly verify or test the setup.

## Design overview and choices
Despite its simplicity, this stage implements the basics of a design that we've seen working well for a variety of customers.

The approach adapts to different high-level requirements: 
- boundaries for each step
- clear and defined actors
- least privilege principle
- rely on service account impersonification

The code in this example doesn't address Organization level configuration (Organization policy, VPC-SC, centralized logs). Those are aspects that we expect to be addressed on stages external to this script. 

### Project structure
The DP is designed to rely on several projects, one project per data stage. The stages identified are:
- landing
- load
- data lake
- orchestration
- transformation
- exposure

This is done to better separate different stages of the data journey and rely on project-level roles.

The following projects will be created:
- **Landing** This project is intended to store data temporarily. Data are pushed to Cloud Storage, BigQuery or Cloud PubSub. Resource configured with 3 months lifecycle policy.
- **Load** This project is intended to load data from `landing` to `data lake`. Load is made with minimal to zero transformation logic (mainly `cast`). Anonymization/tokenization Personally Identifiable Information can be applied at this stage or in the transformation stage depending on your requirements. The use of [Cloud Dataflow templates](https://cloud.google.com/dataflow/docs/concepts/dataflow-templates) is suggested.
- **Data Lake** Those projects are intended to store your data. It represents where data will be persisted within 3 Layers. These layers represent different stages where data is processed and progressively refined
  - **L0 - Raw data** Structured Data, stored in the adequate format: structured data stored in BigQuery, unstructured data stored on Cloud Storage with additional metadata stored in BigQuery (for example pictures stored in Cloud Storage and analysis of the picture for Cloud Vision API stored in BigQuery). 
  - **L1 - Cleansed, aggregated and standardized data**
  - **L2 - Curated layer**
  - **Playground** Store temporary tables that Data Analyst may use to perform R&D on data available on other Data Lake layers
- **Orchestration** This project is intended to host Cloud Composer. Cloud Composer will orchestrate all tasks to move your data on its journey.
- **Transformation** This project is intended to host resources to move data from one layer of the Data Lake to the other. We strongly suggest relying on BigQuery engine to perform transformations. If BigQuery doesn't have the feature needed to perform your transformation you suggest using Cloud Dataflow. The use of [Cloud Dataflow templates](https://cloud.google.com/dataflow/docs/concepts/dataflow-templates) is suggested. Anonymization/tokenization Personally Identifiable Information can be applied at this stage or in the transformation stage depending on your requirements.
- **Exposure** This project is intended to host resources to expose your data. To expose BigQuery data, we strongly suggest relying on Authorized views. Other resources may better fit a particular data access pattern, example: Cloud SQL may be needed if you need to expose data with low latency, BigTable may be needed in a use case where you need lower latency to access data. For the porpuse of this example, no resources will be deployed on this project, please customize the exple as needed.

### Roles
We assigned roles on resources at project-level assigning the appropriate role to groups. We recommend not adding human users directly to the resource-access groups with IAM permissions to access data.

### Service accounts
Service Account creation follows the following principles:
- Each service account perform a single task having access to the minimum number of resources (example: the Cloud Dataflow Service Account has access to the Landing project and to the Data Lake L0 project)
- Each Service Account has the least privilege on each project.

#### Service Account Keys
Service Account Keys (SAK) are out of scope for this example. The example implemented relies on Service Account Impersonification avoiding the creation of SAK.

The use of SAK within a data pipeline incurs several security risks, as these are physical credentials, matched to an automated system, that can be distributed without oversight or control. 

Whilst necessary in some scenarios, such as programmatic access from on-premise or alternative clouds, we recommend identifying a structured process to mitigate risks associated with the use of service account keys.

### Groups
As default groups, we identified the following actors:
- *Data Engineers*: the group that handles and runs the Data Hub. The group has Read access to all resources to be able to troubleshoot possible issues with the pipeline. The team also can impersonate all service accounts. Default value: `gcp-data-engineers@DOMAIN.COM`. 
- *Data Analyst*: the group that performs analysis on the dataset. The group has Read access to the Data Lake L2 project and BigQuery READ/WRITE access to the `playground` project. Default value: `gcp-data-analyst@DOMAIN.COM`
- *Data Security*: the project that handles security features related to the Data Hub. Default name: `gcp-data-security@DOMAIN.com`
### Virtual Private Cloud (VPC) design
The DP except as input an existing [Shared-VPC](https://cloud.google.com/vpc/docs/shared-vpc) to run resources. You can configure subsets for DP resources specifying the link to the subnet in the `network_config` variable. You may want to configure a shared-VPC to run your resources in the case your pipelines may need to reach on-premise resources.

If `network_config` variable is not configured, the script will create a VPC on each project that requires a VPC: *load*, *transformation*, and *orchestration* projects with the default configuration.
### IP ranges, subnetting
To run your DP resources you need the following ranges:
- Load project VPC for Cloud Dataflow workers. Range: '/24'.
- Transformation VPC for Cloud Dataflow workers. Range: '/24'.
- Orchestration VPC for Cloud Composer:
  - Cloud SQL. Range: '/24'
  - GKE Master. Range: '/28'
  - Web Server: Range: '/28'
  - Secondary IP ranges. Pods range: '/22', Services range: '/24'

### Resource naming convention
Resources in the script use the following acronyms:
 - `lnd` for `landing`
 - `lod` for `load`
 - `orc` for `orchestration`
 - `trf` for `transformation`
 - `dtl` for `Data Lake`
 - 2 letters acronym for GCP products, example: `bq` for `BigQuery`, `df` for `Cloud Dataflow`, ...

Resources follow the naming convention described below.

Projects:
```
PREFIX-LAYER
```

Services:
```
PREFIX-LAYER[2]-GCP_PRODUCT[2]-COUNTER
```

Service Accounts:
```
PREFIX-LAYER[2]-GCP_PRODUCT[2]-COUNTER
```

### Encryption
We suggest a centralized approach to Keys management, to let the Security team be the only team that can access encryption material. Keyrings and Keys belong to a project external to the DP. 

![Centralized Cloud Key Management high-level diagram](./images/kms_diagram.png "Centralized Cloud Key Management high-level diagram")

To configure the use of Cloud Key Management on resources you have to specify the key URL on the 'service_encryption_keys'. Keys location should match the resource location. Example:

```
service_encryption_keys = {
    bq       = "KEY_URL_MULTIREGIONAL"
    composer = "KEY_URL_REGIONAL"
    dataflow = "KEY_URL_REGIONAL"
    storage  = "KEY_URL_MULTIREGIONAL"
    pubsub   = "KEY_URL_MULTIREGIONAL"
```

We consider this step optional, it depends on customer policy and security best practices.

## Data Anonymization
We suggest the use of Cloud Data Loss Prevention to identify/mask/tokenize your confidential data. The implementation of the Data Loss Prevention strategy is out of scope for this example. We enable the service in 2 different projects to let you implement the data loss prevention strategy. We expect you will use [Cloud Data Loss Prevention templates](https://cloud.google.com/dlp/docs/concepts-templates) in one of the following ways:
- During the ingestion phase, from Dataflow
- During the transformation phase, from [BigQuery](https://cloud.google.com/bigquery/docs/scan-with-dlp) or [Cloud Dataflow](https://cloud.google.com/architecture/running-automated-dataflow-pipeline-de-identify-pii-dataset)

We implemented a centralized model for Cloud Data Loss Prevention resources. Templates will be stored in the security project:

![Centralized Cloud Data Loss Prevention high-level diagram](./images/dlp_diagram.png "Centralized Cloud Data Loss Prevention high-level diagram")

## How to run this script
In order to bring up this example, you will need

- a folder or organization where new projects will be created
- a billing account that will be associated to new projects

The DP is meant to be executed by a Service Account (or a regular user) having this minimal set of permission:
* **Org level**:
  * `"compute.organizations.enableXpnResource"`
  * `"compute.organizations.disableXpnResource"`
  * `"compute.subnetworks.setIamPolicy"`
* **Folder level**:
  * `"roles/logging.admin"`
  * `"roles/owner"`
  * `"roles/resourcemanager.folderAdmin"`
  * `"roles/resourcemanager.projectCreator"`
* **Cloud Key Management Keys** (if Cloud Key Management keys are configured):
  * `"roles/cloudkms.admin"` or Permissions: `cloudkms.cryptoKeys.getIamPolicy`, `cloudkms.cryptoKeys.list`, `cloudkms.cryptoKeys.setIamPolicy`
* **on the host project** for the Shared VPC/s
  * `"roles/browser"`
  * `"roles/compute.viewer"`
  * `"roles/dns.admin"`

## Variable configuration
There are three sets of variables you will need to fill in:

```
prefix             = "PRFX"
project_create = {
  parent             = "folders/123456789012"
  billing_account_id = "111111-222222-333333"
}
organization = {
  domain = "DOMAIN.com"
}
```

For a more fine grained configuration, check variables on [`variables.tf`](./variables.tf) and update accordingly to the desired configuration.

## Customizations
### Create Cloud Key Management keys as part of the DP
To create Cloud Key Management keys within the DP you can uncomment the Cloud Key Management resources configured in the [`06-sec-main.tf`](./06-sec-main.tf) file and update Cloud Key Management keys pointers on `local.service_encryption_keys.*` to the local resource created.

### Assign roles at BQ Dataset level
To handle multiple groups of `data-analysts` accessing the same Data Lake layer projects but only to the dataset belonging to a specific group, you may want to assign roles at BigQuery dataset level instead of at project-level. 
To do this, you need to remove IAM binging at project-level for the `data-analysts` group and assign roles at BigQuery dataset level using the `iam` variable on `bigquery-dataset` modules.

## Demo pipeline
The application layer is out of scope of this script, but as a demo, it is provided with a Cloud Composer DAG to mode data from the `landing` area to the `DataLake L2` dataset.

Just follow the commands you find in the `demo_commands` Terraform output, go in the Cloud Composer UI and run the `data_pipeline_dag`.

Description of commands:
- 01: copy sample data to a `landing` Cloud Storage bucket impersonating the `load` service account.
- 02: copy sample data structure definition in the `orchestration` Cloud Storage bucket impersonating the `orchestration` service account.
- 03: copy the Cloud Composer DAG to the Cloud Composer Storage bucket impersonating the `orchestration` service account.
- 04: Open the Cloud Composer Airflow UI and run the imported DAG.
- 05: Run the BigQuery query to see results.
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [organization](variables.tf#L76) | Organization details. | <code title="object&#40;&#123;&#10;  domain &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [prefix](variables.tf#L83) | Unique prefix used for resource names. Not used for projects if 'project_create' is null. | <code>string</code> | ✓ |  |
| [composer_config](variables.tf#L17) |  | <code title="object&#40;&#123;&#10;  ip_range_cloudsql   &#61; string&#10;  ip_range_gke_master &#61; string&#10;  ip_range_web_server &#61; string&#10;  region              &#61; string&#10;  secondary_ip_range &#61; object&#40;&#123;&#10;    pods     &#61; string&#10;    services &#61; string&#10;  &#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  ip_range_cloudsql   &#61; &#34;10.20.10.0&#47;24&#34;&#10;  ip_range_gke_master &#61; &#34;10.20.11.0&#47;28&#34;&#10;  ip_range_web_server &#61; &#34;10.20.11.16&#47;28&#34;&#10;  region              &#61; &#34;europe-west1&#34;&#10;  secondary_ip_range &#61; &#123;&#10;    pods     &#61; &#34;10.10.8.0&#47;22&#34;&#10;    services &#61; &#34;10.10.12.0&#47;24&#34;&#10;  &#125;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [data_force_destroy](variables.tf#L40) | Flag to set 'force_destroy' on data services like BiguQery or Cloud Storage. | <code>bool</code> |  | <code>false</code> |
| [groups](variables.tf#L46) | Groups. | <code>map&#40;string&#41;</code> |  | <code title="&#123;&#10;  data-analysts  &#61; &#34;gcp-data-analysts&#34;&#10;  data-engineers &#61; &#34;gcp-data-engineers&#34;&#10;  data-security  &#61; &#34;gcp-data-security&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [location_config](variables.tf#L128) | Locations where resources will be deployed. Map to configure region and multiregion specs. | <code title="object&#40;&#123;&#10;  region       &#61; string&#10;  multi_region &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  region       &#61; &#34;europe-west1&#34;&#10;  multi_region &#61; &#34;eu&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [network_config](variables.tf#L56) | Shared VPC to use. If not null networks will be created in projects. | <code title="object&#40;&#123;&#10;  network &#61; string&#10;  vpc_subnet_range &#61; object&#40;&#123;&#10;    load           &#61; string&#10;    transformation &#61; string&#10;    orchestration  &#61; string&#10;  &#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  network &#61; null&#10;  vpc_subnet_range &#61; &#123;&#10;    load           &#61; &#34;10.10.0.0&#47;24&#34;&#10;    transformation &#61; &#34;10.10.0.0&#47;24&#34;&#10;    orchestration  &#61; &#34;10.10.0.0&#47;24&#34;&#10;  &#125;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [project_create](variables.tf#L88) | Provide values if project creation is needed, uses existing project if null. Parent is in 'folders/nnn' or 'organizations/nnn' format. | <code title="object&#40;&#123;&#10;  billing_account_id &#61; string&#10;  parent             &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [project_id](variables.tf#L97) | Project id, references existing project if `project_create` is null. | <code title="object&#40;&#123;&#10;  landing       &#61; string&#10;  load          &#61; string&#10;  orchestration &#61; string&#10;  trasformation &#61; string&#10;  datalake      &#61; string&#10;  security      &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  landing       &#61; &#34;lnd&#34;&#10;  load          &#61; &#34;lod&#34;&#10;  orchestration &#61; &#34;orc&#34;&#10;  trasformation &#61; &#34;trf&#34;&#10;  datalake      &#61; &#34;dtl&#34;&#10;  security      &#61; &#34;sec&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [project_services](variables.tf#L117) | List of core services enabled on all projects. | <code>list&#40;string&#41;</code> |  | <code title="&#91;&#10;  &#34;cloudresourcemanager.googleapis.com&#34;,&#10;  &#34;iam.googleapis.com&#34;,&#10;  &#34;serviceusage.googleapis.com&#34;,&#10;  &#34;stackdriver.googleapis.com&#34;&#10;&#93;">&#91;&#8230;&#93;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [VPC](outputs.tf#L61) | VPC networks. |  |
| [bigquery-datasets](outputs.tf#L17) | BigQuery datasets. |  |
| [demo_commands](outputs.tf#L70) | Demo commands. |  |
| [gcs-buckets](outputs.tf#L28) | GCS buckets. |  |
| [kms_keys](outputs.tf#L42) | Cloud MKS keys. |  |
| [projects](outputs.tf#L47) | GCP Projects. |  |

<!-- END TFDOC -->
## TODOs
Features to add in future releases:
 * Add support for Column level access on BigQuery
 * Add example templates for Data Catalog
 * Add example on how to use Cloud Data Loss Prevention
 * Add solution to handle Tables, Views, and Authorized Views lifecycle
 * Add solution to handle Metadata lifecycle

## To Test/Fix
 * Composer require "Require OS Login" not enforced
 * External Shared-VPC