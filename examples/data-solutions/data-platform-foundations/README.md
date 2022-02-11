# Data Platform

This module implements an opinionated Data Platform Architecture that creates and sets up projects and related resources, to be used to create your end to end data environment.

The code is intentionally simple, as it's intended to provide a generic initial setup and then allow easy customizations to complete the implementation of the intended design.

The following diagram is a high-level reference of the resources created and managed here:

![Data Platform architecture overview](./images/overview_diagram.png "Data Platform architecture overview")

A demo pipeline is also part of this example: it can be built and run on top of the foundational infrastructure to verify or test the setup quickly.

## Design overview and choices

Despite its simplicity, this stage implements the basics of a design that we've seen working well for various customers.

The approach adapts to different high-level requirements:

- boundaries for each step
- clear and defined actors
- least privilege principle
- rely on service account impersonation

The code in this example doesn't address Organization level configuration (Organization policy, VPC-SC, centralized logs). We expect to address those aspects on stages external to this script.

### Project structure

The Data Platform is designed to rely on several projects, one project per data stage. The stages identified are:

- landing
- load
- data lake
- orchestration
- transformation
- exposure

This separation into projects allows adhering the least-privilege principle relying on project-level roles.

The script will create the following projects:

- **Landing** This project is intended to store data temporarily. Data are pushed to Cloud Storage, BigQuery, or Cloud PubSub. Resource configured with 3-months lifecycle policy.
- **Load** This project is intended to load data from `landing` to the `data lake`. The load is made with minimal to zero transformation logic (mainly `cast`). This stage can anonymization/tokenization Personally Identifiable Information (PII). Alternatively, it can be done in the transformation stage depending on your requirements. The use of [Cloud Dataflow templates](https://cloud.google.com/dataflow/docs/concepts/dataflow-templates) is recommended.
- **Data Lake** projects where data are stored. itìs composed of 3 layers that progressively process and define data:
  - **L0 - Raw data** Structured Data, stored in the adequate format: structured data stored in BigQuery, unstructured data stored on Cloud Storage with additional metadata stored in BigQuery (for example pictures stored in Cloud Storage and analysis of the images for Cloud Vision API stored in BigQuery).
  - **L1 - Cleansed, aggregated and standardized data**
  - **L2 - Curated layer**
  - **Playground** Store temporary tables that Data Analyst may use to perform R&D on data available on other Data Lake layers
- **Orchestration** This project is intended to host Cloud Composer. Cloud Composer will orchestrate all tasks to move your data on its journey.
- **Transformation** This project is used to move data between layers of the Data Lake. We strongly suggest relying on BigQuery engine to perform transformations. If BigQuery doesn't have the feature needed to perform your transformation you recommend using Cloud Dataflow together with [Cloud Dataflow templates](https://cloud.google.com/dataflow/docs/concepts/dataflow-templates). This stage can optionally be used to anonymiza/tokenize PII.
- **Exposure** This project is intended to host resources to share your processed data with external systems your data. For the porpuse of this example we leace this project empty. Depending on the access pattern, data can be presented on Cloud SQL, BigQuery, or Bigtable. For BigQuery data, we strongly suggest relying on [Authorized views](https://cloud.google.com/bigquery/docs/authorized-views).

### Roles

We assign roles on resources at project level setting the appropriate role to groups. We recommend not adding human users directly to the resource-access groups with IAM permissions to access data.

### Service accounts

Service account creation follows the least privilege principle, performing a single task which requires access to a defined set of resources. In the table below you can find an high level overview on roles for each service account on each data layer. For semplicy `READ` or `WRITE` roles are used, for detailed roles please refer to the code.


|Service Account|Landing|DataLake L0|DataLake L1|DataLake L2|
|-|:-:|:-:|:-:|:-:|
|landing-sa|WRITE|-|-|-|
|load-sa|READ|READ/WRITE|-|-|
|transformation-sa|-|READ/WRITE|READ/WRITE|READ/WRITE|
|orchestration-sa|-|-|-|-|

- Each service account perform a single task having access to the minimum number of resources (example: the Cloud Dataflow Service Account has access to the Landing project and the Data Lake L0 project)
- Each Service Account has the least privilege on each project.

#### Service Account Keys

The use of SAK within a data pipeline incurs several security risks, as these credentials, that could be leaked without oversight or control. This example relies on Service Account Impersonation to avoid the creation of private keys.

### User groups

User groups are important. They provide a stable frame of reference that allows decoupling the final set of permissions for each group, from the stage where entities and resources are created and their IAM bindings defined.

We use three groups to control access to resources:

- *Data Engineers* They handle and run the Data Hub, with read access to all resources in order to troubleshoot possible issues with pipelines. This team can also impersonate any service account.
- *Data Analyst*. They perform analysis on datasets, with read access to the data lake L2 project, and BigQuery READ/WRITE access to the playground project. 
- *Data Security*:. They handle security configurations related to the Data Hub. This team has admin access to the common project to configure Cloud DLP templates or Data Catalog policy tags.

In the table below you can find an high level overview on roles for each group on each project. For semplicy `READ`, `WRITE` and `ADMIN` roles are used, for detailed roles please refer to the code.

|Group|Landing|Load|Transformation|Data Lake L0|Data Lake L1|Data Lake L2|Data Lake Playground|Orchestration|Common|
|-|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|Data Engineers|ADMIN|ADMIN|ADMIN|ADMIN|ADMIN|ADMIN|ADMIN|ADMIN|ADMIN|
|Data Analyst|-|-|-|-|-|READ|READ/WRITE|-|-|
|Data Security|-|-|-|-|-|-|-|-|ADMIN|

### Groups

We use thress groups based on the required access:

- *Data Engineers*: the group that handles and runs the Data Hub. The group has Read access to all resources to troubleshoot possible issues with the pipeline. The team also can impersonate all service accounts. Default value: `gcp-data-engineers@DOMAIN.COM`.
- *Data Analyst*: the group that performs analysis on the dataset. The group has Read access to the Data Lake L2 project and BigQuery READ/WRITE access to the `playground` project. Default value: `gcp-data-analyst@DOMAIN.COM`
- *Data Security*: the group handling security configurations related to the Data Hub. Default name: `gcp-data-security@DOMAIN.com`

### Virtual Private Cloud (VPC) design

The Data Platform accepts as input an existing [Shared-VPC](https://cloud.google.com/vpc/docs/shared-vpc) to run resources. You can configure subnets for data resources by specifying the link to the subnet in the `network_config` variable. You may want to configure a shared-VPC to host your resources if your pipelines may need to reach on-premise resources.

If `network_config` variable is not provided, the script will create a VPC on each project that requires a VPC: *load*, *transformation*, and *orchestration* projects with the default configuration.

### IP ranges, subnetting

To deploy your Data Platform you need the following ranges:

- Load project VPC for Cloud Dataflow workers. Range: '/24'.
- Transformation VPC for Cloud Dataflow workers. Range: '/24'.
- Orchestration VPC for Cloud Composer:
  - Cloud SQL. Range: '/24'
  - GKE Master. Range: '/28'
  - Web Server: Range: '/28'
  - Secondary IP ranges. Pods range: '/22', Services range: '/24'

### Resource naming convention

Resources follow the naming convention described below.

- `prefix-layer` for projects
- `prefix-layer-prduct` for resources
- `prefix-layer[2]-gcp-product[2]-counter` for services and service accounts

### Encryption

We suggest a centralized approach to key management, where Organization Security is the only team that can access encryption material, and keyrings and keys are managed in a project external to the DP.

![Centralized Cloud Key Management high-level diagram](./images/kms_diagram.png "Centralized Cloud Key Management high-level diagram")

To configure the use of Cloud Key Management on resources you have to specify the key URL on the 'service_encryption_keys'. Keys location should match the resource location. Example:

```hcl
service_encryption_keys = {
  bq       = "KEY_URL_MULTIREGIONAL"
  composer = "KEY_URL_REGIONAL"
  dataflow = "KEY_URL_REGIONAL"
  storage  = "KEY_URL_MULTIREGIONAL"
  pubsub   = "KEY_URL_MULTIREGIONAL"
```

We consider this step optional, it depends on customer policy and security best practices.

## Data Anonymization

We suggest using Cloud Data Loss Prevention to identify/mask/tokenize your confidential data. Implementing the Data Loss Prevention strategy is out of scope for this example. We enable the service in 2 different projects to implement the data loss prevention strategy. We expect you will use [Cloud Data Loss Prevention templates](https://cloud.google.com/dlp/docs/concepts-templates) in one of the following ways:

- During the ingestion phase, from Dataflow
- During the transformation phase, from [BigQuery](https://cloud.google.com/bigquery/docs/scan-with-dlp) or [Cloud Dataflow](https://cloud.google.com/architecture/running-automated-dataflow-pipeline-de-identify-pii-dataset)

We implemented a centralized model for Cloud Data Loss Prevention resources. Templates will be stored in the security project:

![Centralized Cloud Data Loss Prevention high-level diagram](./images/dlp_diagram.png "Centralized Cloud Data Loss Prevention high-level diagram")

## How to run this script

To deploy this example on your GCP organization, you will need

- a folder or organization where new projects will be created
- a billing account that will be associated with the new projects

The Data Platform is meant to be executed by a Service Account (or a regular user) having this minimal set of permission:

- Org level
  - `"compute.organizations.enableXpnResource"`
  - `"compute.organizations.disableXpnResource"`
  - `"compute.subnetworks.setIamPolicy"`
- Folder level
  - `"roles/logging.admin"`
  - `"roles/owner"`
  - `"roles/resourcemanager.folderAdmin"`
  - `"roles/resourcemanager.projectCreator"`
- Cloud Key Management Keys** (if Cloud Key Management keys are configured):
  - `"roles/cloudkms.admin"` or Permissions: `cloudkms.cryptoKeys.getIamPolicy`, `cloudkms.cryptoKeys.list`, `cloudkms.cryptoKeys.setIamPolicy`
- on the host project for the Shared VPC/s
  - `"roles/browser"`
  - `"roles/compute.viewer"`
  - `"roles/dns.admin"`

## Variable configuration

There are three sets of variables you will need to fill in:

```hcl
prefix             = "PRFX"
project_create = {
  parent             = "folders/123456789012"
  billing_account_id = "111111-222222-333333"
}
organization = {
  domain = "DOMAIN.com"
}
```

For more fine details check variables on [`variables.tf`](./variables.tf) and update according to the desired configuration. Remember to create team groups described [below](#groups).

Once the configuration is complete, run the project factory by running

```bash
terraform init
terraform apply
```

## Customizations

### Create Cloud Key Management keys as part of the Data Platform

To create Cloud Key Management keys in the Data Platform you can uncomment the Cloud Key Management resources configured in the [`06-common.tf`](./06-common.tf) file and update Cloud Key Management keys pointers on `local.service_encryption_keys.*` to the local resource created.

### Assign roles at BQ Dataset level

To handle multiple groups of `data-analysts` accessing the same Data Lake layer projects but only to the dataset belonging to a specific group, you may want to assign roles at BigQuery dataset level instead of at project-level.
To do this, you need to remove IAM binging at project-level for the `data-analysts` group and give roles at BigQuery dataset level using the `iam` variable on `bigquery-dataset` modules.

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
| [billing_account_id](variables.tf#L17) | Billing account id. | <code>string</code> | ✓ |  |
| [folder_id](variables.tf#L41) | Folder to be used for the networking resources in folders/nnnn format. | <code>string</code> | ✓ |  |
| [organization_domain](variables.tf#L79) | Organization domain. | <code>string</code> | ✓ |  |
| [prefix](variables.tf#L84) | Unique prefix used for resource names. | <code>string</code> | ✓ |  |
| [composer_config](variables.tf#L22) |  | <code title="object&#40;&#123;&#10;  node_count      &#61; number&#10;  airflow_version &#61; string&#10;  env_variables   &#61; map&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  node_count      &#61; 3&#10;  airflow_version &#61; &#34;composer-1.17.5-airflow-2.1.4&#34;&#10;  env_variables   &#61; &#123;&#125;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [data_force_destroy](variables.tf#L35) | Flag to set 'force_destroy' on data services like BiguQery or Cloud Storage. | <code>bool</code> |  | <code>false</code> |
| [groups](variables.tf#L46) | Groups. | <code>map&#40;string&#41;</code> |  | <code title="&#123;&#10;  data-analysts  &#61; &#34;gcp-data-analysts&#34;&#10;  data-engineers &#61; &#34;gcp-data-engineers&#34;&#10;  data-security  &#61; &#34;gcp-data-security&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [network_config](variables.tf#L56) | Shared VPC network configurations to use. If null networks will be created in projects with preconfigured values. | <code title="object&#40;&#123;&#10;  host_project      &#61; string&#10;  network_self_link &#61; string&#10;  subnet_self_links &#61; object&#40;&#123;&#10;    load           &#61; string&#10;    transformation &#61; string&#10;    orchestration  &#61; string&#10;  &#125;&#41;&#10;  composer_ip_ranges &#61; object&#40;&#123;&#10;    cloudsql   &#61; string&#10;    gke_master &#61; string&#10;    web_server &#61; string&#10;  &#125;&#41;&#10;  composer_secondary_ranges &#61; object&#40;&#123;&#10;    pods     &#61; string&#10;    services &#61; string&#10;  &#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [project_services](variables.tf#L89) | List of core services enabled on all projects. | <code>list&#40;string&#41;</code> |  | <code title="&#91;&#10;  &#34;cloudresourcemanager.googleapis.com&#34;,&#10;  &#34;iam.googleapis.com&#34;,&#10;  &#34;serviceusage.googleapis.com&#34;,&#10;  &#34;stackdriver.googleapis.com&#34;&#10;&#93;">&#91;&#8230;&#93;</code> |
| [region](variables.tf#L100) | Region used for regional resources. | <code>string</code> |  | <code>&#34;europe-west1&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [bigquery-datasets](outputs.tf#L17) | BigQuery datasets. |  |
| [demo_commands](outputs.tf#L93) | Demo commands. |  |
| [gcs-buckets](outputs.tf#L28) | GCS buckets. |  |
| [kms_keys](outputs.tf#L42) | Cloud MKS keys. |  |
| [projects](outputs.tf#L47) | GCP Projects informations. |  |
| [vpc_network](outputs.tf#L75) | VPC network. |  |
| [vpc_subnet](outputs.tf#L84) | VPC subnetworks. |  |

<!-- END TFDOC -->

## TODOs

Features to add in future releases

- add support for column level access on BigQuery
- add example templates for Data Catalog
- add example on how to use Cloud Data Loss Prevention
- add solution to handle tables, views, and authorized views lifecycle
- add solution to handle metadata lifecycle

Fixes

- composer requires "Require OS Login" not enforced
- external Shared VPC
