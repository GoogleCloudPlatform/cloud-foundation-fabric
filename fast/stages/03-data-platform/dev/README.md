# Data Platform

The Data Platform builds on top of your foundations to create and set up projects (and related resources) to be used for your data platform.

<p align="center">
  <img src="diagram.png" alt="Data Platform diagram">
</p>

## Design overview and choices

> A more comprehensive description of the Data Platform architecture and approach can be found in the [Data Platform module README](../../../../examples/data-solutions/data-platform-foundations/). The module is wrapped and configured here to leverage the FAST flow.

The Data Platform creates projects in a well-defined context, usually an ad-hoc folder  managed by the resource management setup. Resources are organized by environment within this folder.

Across different data layers environment-specific projects are created to separate resources and IAM roles.

The Data Platform manages:

- project creation
- API/Services enablement
- service accounts creation
- IAM role assignment for groups and service accounts
- KMS keys roles assignment
- Shared VPC attachment and subnet IAM binding
- project-level organization policy definitions
- billing setup (billing account attachment and budget configuration)
- data-related resources in the managed projects

### User groups

As per our GCP best practices the Data Platform relies on user groups to assign roles to human identities. These are the specific groups used by the Data Platform and their access patterns, from the [module documentation](../../../../examples/data-solutions/data-platform-foundations/#groups):

- *Data Engineers* They handle and run the Data Hub, with read access to all resources in order to troubleshoot possible issues with pipelines. This team can also impersonate any service account.
- *Data Analysts*. They perform analysis on datasets, with read access to the data lake L2 project, and BigQuery READ/WRITE access to the playground project.
- *Data Security*:. They handle security configurations related to the Data Hub. This team has admin access to the common project to configure Cloud DLP templates or Data Catalog policy tags.

|Group|Landing|Load|Transformation|Data Lake L0|Data Lake L1|Data Lake L2|Data Lake Playground|Orchestration|Common|
|-|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|Data Engineers|`ADMIN`|`ADMIN`|`ADMIN`|`ADMIN`|`ADMIN`|`ADMIN`|`ADMIN`|`ADMIN`|`ADMIN`|
|Data Analysts|-|-|-|-|-|`READ`|`READ`/`WRITE`|-|-|
|Data Security|-|-|-|-|-|-|-|-|`ADMIN`|

### Network

A Shared VPC is used here, either from one of the FAST networking stages (e.g. [hub and spoke via VPN](../../02-networking-vpn)) or from an external source.

### Encryption

Cloud KMS crypto keys can be configured wither from the [FAST security stage](../../02-security) or from an external source. This step is optional and depends on customer policies and security best practices.

To configure the use of Cloud KMS on resources, you have to specify the key id on the `service_encryption_keys` variable. Key locations should match resource locations.

### VPC-SC

As is often the case in real-world configurations, [VPC-SC](https://cloud.google.com/vpc-service-controls) is needed to mitigate data exfiltration. VPC-SC can be configured from the [FAST security stage](../../02-security). This step is optional, but highly recomended, and depends on customer policies and security best practices.

To configure the use of VPC-SC on the data platform, you have to specify the data platform project numbers on the `vpc_sc_perimeter_projects.dev` variable on [FAST security stage](../../02-security#perimeter-resources).

## How to run this stage

This stage can be run in isolation by prviding the necessary variables, but it's really meant to be used as part of the FAST flow after the "foundational stages" ([`00-bootstrap`](../../00-bootstrap), [`01-resman`](../../01-resman), [`02-networking`](../../02-networking-vpn) and [`02-security`](../../02-security)).

When running in isolation, the following roles are needed on the principal used to apply Terraform:

- on the organization or network folder level
  - `roles/xpnAdmin` or a custom role which includes the following permissions
    - `"compute.organizations.enableXpnResource"`,
    - `"compute.organizations.disableXpnResource"`,
    - `"compute.subnetworks.setIamPolicy"`,
- on each folder where projects are created
  - `"roles/logging.admin"`
  - `"roles/owner"`
  - `"roles/resourcemanager.folderAdmin"`
  - `"roles/resourcemanager.projectCreator"`
- on the host project for the Shared VPC
  - `"roles/browser"`
  - `"roles/compute.viewer"`
- on the organization or billing account
  - `roles/billing.admin`

The VPC host project, VPC and subnets should already exist.

### Providers configuration

If you're running this on top of Fast, you should run the following commands to create the providers file, and populate the required variables from the previous stage.

```bash
# Variable `outputs_location` is set to `~/fast-config` in stage 01-resman
ln -s ~/fast-config/providers/03-data-platform-dev-providers.tf .
```

### Variable configuration

There are two broad sets of variables that can be configured:

- variables shared by other stages (organization id, billing account id, etc.) or derived from a resource managed by a different stage (folder id, automation project id, etc.)
- variables specific to resources managed by this stage

To avoid the tedious job of filling in the first group of variables with values derived from other stages' outputs, the same mechanism used above for the provider configuration can be used to leverage pre-configured `.tfvars` files.

If you configured a valid path for `outputs_location` in the bootstrap security and networking stages, simply link the relevant `terraform-*.auto.tfvars.json` files from this stage's outputs folder under the path you specified. This will also link the providers configuration file:

```bash
# Variable `outputs_location` is set to `~/fast-config`
ln -s ~/fast-config/tfvars/00-bootstrap.auto.tfvars.json .
ln -s ~/fast-config/tfvars/01-resman.auto.tfvars.json . 
ln -s ~/fast-config/tfvars/02-networking.auto.tfvars.json .
```

If you're not using FAST or its output files, refer to the [Variables](#variables) table at the bottom of this document for a full list of variables, their origin (e.g., a stage or specific to this one), and descriptions explaining their meaning.

Once the configuration is complete you can apply this stage:

```bash
terraform init
terraform apply
```

<!-- TFDOC OPTS files:1 show_extra:1 -->
<!-- BEGIN TFDOC -->

## Files

| name | description | modules |
|---|---|---|
| [main.tf](./main.tf) | Data Platformy. | <code>data-platform-foundations</code> |
| [outputs.tf](./outputs.tf) | Output variables. |  |
| [variables.tf](./variables.tf) | Terraform Variables. |  |

## Variables

| name | description | type | required | default | producer |
|---|---|:---:|:---:|:---:|:---:|
| [billing_account](variables.tf#L17) | Billing account id and organization id ('nnnnnnnn' or null). | <code title="object&#40;&#123;&#10;  id              &#61; string&#10;  organization_id &#61; number&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>00-globals</code> |
| [folder_ids](variables.tf#L45) | Folder to be used for the networking resources in folders/nnnn format. | <code title="object&#40;&#123;&#10;  data-platform &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>01-resman</code> |
| [host_project_ids](variables.tf#L63) | Shared VPC project ids. | <code title="object&#40;&#123;&#10;  dev-spoke-0 &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>02-networking</code> |
| [organization](variables.tf#L89) | Organization details. | <code title="object&#40;&#123;&#10;  domain      &#61; string&#10;  id          &#61; number&#10;  customer_id &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>00-globals</code> |
| [prefix](variables.tf#L105) | Unique prefix used for resource names. Not used for projects if 'project_create' is null. | <code>string</code> | ✓ |  | <code>00-globals</code> |
| [composer_config](variables.tf#L26) |  | <code title="object&#40;&#123;&#10;  node_count      &#61; number&#10;  airflow_version &#61; string&#10;  env_variables   &#61; map&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  node_count      &#61; 3&#10;  airflow_version &#61; &#34;composer-1.17.5-airflow-2.1.4&#34;&#10;  env_variables   &#61; &#123;&#125;&#10;&#125;">&#123;&#8230;&#125;</code> |  |
| [data_force_destroy](variables.tf#L39) | Flag to set 'force_destroy' on data services like BigQery or Cloud Storage. | <code>bool</code> |  | <code>false</code> |  |
| [groups](variables.tf#L53) | Groups. | <code>map&#40;string&#41;</code> |  | <code title="&#123;&#10;  data-analysts  &#61; &#34;gcp-data-analysts&#34;&#10;  data-engineers &#61; &#34;gcp-data-engineers&#34;&#10;  data-security  &#61; &#34;gcp-data-security&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |  |
| [network_config_composer](variables.tf#L71) | Network configurations to use for Composer. | <code title="object&#40;&#123;&#10;  cloudsql_range    &#61; string&#10;  gke_master_range  &#61; string&#10;  gke_pods_name     &#61; string&#10;  gke_services_name &#61; string&#10;  web_server_range  &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  cloudsql_range    &#61; &#34;192.168.254.0&#47;24&#34;&#10;  gke_master_range  &#61; &#34;192.168.255.0&#47;28&#34;&#10;  gke_pods_name     &#61; &#34;pods&#34;&#10;  gke_services_name &#61; &#34;services&#34;&#10;  web_server_range  &#61; &#34;192.168.255.16&#47;28&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |  |
| [outputs_location](variables.tf#L99) | Path where providers, tfvars files, and lists for the following stages are written. Leave empty to disable. | <code>string</code> |  | <code>null</code> |  |
| [project_services](variables.tf#L111) | List of core services enabled on all projects. | <code>list&#40;string&#41;</code> |  | <code title="&#91;&#10;  &#34;cloudresourcemanager.googleapis.com&#34;,&#10;  &#34;iam.googleapis.com&#34;,&#10;  &#34;serviceusage.googleapis.com&#34;,&#10;  &#34;stackdriver.googleapis.com&#34;&#10;&#93;">&#91;&#8230;&#93;</code> |  |
| [region](variables.tf#L122) | Region used for regional resources. | <code>string</code> |  | <code>&#34;europe-west1&#34;</code> |  |
| [service_encryption_keys](variables.tf#L128) | Cloud KMS to use to encrypt different services. Key location should match service region. | <code title="object&#40;&#123;&#10;  bq       &#61; string&#10;  composer &#61; string&#10;  dataflow &#61; string&#10;  storage  &#61; string&#10;  pubsub   &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |  |
| [subnet_self_links](variables.tf#L140) | Shared VPC subnet self links. | <code title="object&#40;&#123;&#10;  dev-spoke-0 &#61; map&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> | <code>02-networking</code> |
| [vpc_self_links](variables.tf#L149) | Shared VPC self links. | <code title="object&#40;&#123;&#10;  dev-spoke-0 &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> | <code>02-networking</code> |

## Outputs

| name | description | sensitive | consumers |
|---|---|:---:|---|
| [bigquery_datasets](outputs.tf#L17) | BigQuery datasets. |  |  |
| [demo_commands](outputs.tf#L47) | Demo commands. |  |  |
| [gcs_buckets](outputs.tf#L22) | GCS buckets. |  |  |
| [kms_keys](outputs.tf#L27) | Cloud MKS keys. |  |  |
| [projects](outputs.tf#L32) | GCP Projects informations. |  |  |
| [vpc_network](outputs.tf#L37) | VPC network. |  |  |
| [vpc_subnet](outputs.tf#L42) | VPC subnetworks. |  |  |

<!-- END TFDOC -->
