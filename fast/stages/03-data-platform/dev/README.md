# Data Platform

The Data Platform builds on top of your foundations to create and set up projects (and related resources) to be used for your data platform.

<p align="center">
  <img src="diagram.png" alt="Data Platform diagram">
</p>

## Design overview and choices

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

More details on this architecture and approach are described in the [Data Platform module](../../../../examples/data-solutions/data-platform-foundations/), which is lightly wrapped and leveraged here.

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

Cloud KMS crypto keys are used here by default, wither from the [FAST security stage](../../02-security) or from an external source.

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

If you're running this as part of a full FAST flow and using output files, the providers configuration with the right bucket and impersionation account is already available, and will be linked in via the same command use for variables and described in the next section.

### Variable configuration

There are two broad sets of variables that can be configured:

- variables shared by other stages (organization id, billing account id, etc.) or derived from a resource managed by a different stage (folder id, automation project id, etc.)
- variables specific to resources managed by this stage

To avoid the tedious job of filling in the first group of variables with values derived from other stages' outputs, the same mechanism used above for the provider configuration can be used to leverage pre-configured `.tfvars` files.

If you configured a valid path for `outputs_location` in the bootstrap security and networking stages, simply link the relevant `terraform-*.auto.tfvars.json` files from this stage's outputs folder under the path you specified. This will also link the providers configuration file:

```bash
# variable `outputs_location` set to `../../../config`
ln -s ../../../config/03-data-platform-prod/* ./
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

| name | description | modules | resources |
|---|---|---|---|
| [main.tf](./main.tf) | Data Platformy. | <code>data-platform-foundations</code> |  |
| [outputs.tf](./outputs.tf) | Output variables. |  | <code>local_file</code> |
| [variables.tf](./variables.tf) | Terraform Variables. |  |  |

## Variables

| name | description | type | required | default | producer |
|---|---|:---:|:---:|:---:|:---:|
| [billing_account_id](variables.tf#L17) | Billing account id. | <code>string</code> | ✓ |  | <code>00-bootstrap</code> |
| [folder_id](variables.tf#L42) | Folder to be used for the networking resources in folders/nnnn format. | <code>string</code> | ✓ |  | <code>resman</code> |
| [network_config](variables.tf#L58) | Network configurations to use. Specify a shared VPC to use, if null networks will be created in projects. | <code title="object&#40;&#123;&#10;  host_project      &#61; string&#10;  network_self_link &#61; string&#10;  subnet_self_links &#61; object&#40;&#123;&#10;    load           &#61; string&#10;    transformation &#61; string&#10;    orchestration  &#61; string&#10;  &#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |  |
| [organization_domain](variables.tf#L97) | Organization domain. | <code>string</code> | ✓ |  |  |
| [prefix](variables.tf#L108) | Unique prefix used for resource names. Not used for projects if 'project_create' is null. | <code>string</code> | ✓ |  | <code>00-bootstrap</code> |
| [composer_config](variables.tf#L23) |  | <code title="object&#40;&#123;&#10;  node_count      &#61; number&#10;  airflow_version &#61; string&#10;  env_variables   &#61; map&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  node_count      &#61; 3&#10;  airflow_version &#61; &#34;composer-1.17.5-airflow-2.1.4&#34;&#10;  env_variables   &#61; &#123;&#125;&#10;&#125;">&#123;&#8230;&#125;</code> |  |
| [data_force_destroy](variables.tf#L36) | Flag to set 'force_destroy' on data services like BiguQery or Cloud Storage. | <code>bool</code> |  | <code>false</code> |  |
| [groups](variables.tf#L48) | Groups. | <code>map&#40;string&#41;</code> |  | <code title="&#123;&#10;  data-analysts  &#61; &#34;gcp-data-analysts&#34;&#10;  data-engineers &#61; &#34;gcp-data-engineers&#34;&#10;  data-security  &#61; &#34;gcp-data-security&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |  |
| [network_config_composer](variables.tf#L71) | Network configurations to use for Composer. | <code title="object&#40;&#123;&#10;  composer_ip_ranges &#61; object&#40;&#123;&#10;    cloudsql   &#61; string&#10;    gke_master &#61; string&#10;    web_server &#61; string&#10;  &#125;&#41;&#10;  composer_secondary_ranges &#61; object&#40;&#123;&#10;    pods     &#61; string&#10;    services &#61; string&#10;  &#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  composer_ip_ranges &#61; &#123;&#10;    cloudsql   &#61; &#34;172.18.29.0&#47;24&#34;&#10;    gke_master &#61; &#34;172.18.30.0&#47;28&#34;&#10;    web_server &#61; &#34;172.18.30.16&#47;28&#34;&#10;  &#125;&#10;  composer_secondary_ranges &#61; &#123;&#10;    pods     &#61; &#34;pods&#34;&#10;    services &#61; &#34;services&#34;&#10;  &#125;&#10;&#125;">&#123;&#8230;&#125;</code> |  |
| [outputs_location](variables.tf#L102) | Path where providers, tfvars files, and lists for the following stages are written. Leave empty to disable. | <code>string</code> |  | <code>null</code> |  |
| [project_services](variables.tf#L114) | List of core services enabled on all projects. | <code>list&#40;string&#41;</code> |  | <code title="&#91;&#10;  &#34;cloudresourcemanager.googleapis.com&#34;,&#10;  &#34;iam.googleapis.com&#34;,&#10;  &#34;serviceusage.googleapis.com&#34;,&#10;  &#34;stackdriver.googleapis.com&#34;&#10;&#93;">&#91;&#8230;&#93;</code> |  |
| [region](variables.tf#L125) | Region used for regional resources. | <code>string</code> |  | <code>&#34;europe-west1&#34;</code> |  |

## Outputs

| name | description | sensitive | consumers |
|---|---|:---:|---|
| [bigquery_datasets](outputs.tf#L28) | BigQuery datasets. |  |  |
| [demo_commands](outputs.tf#L58) | Demo commands. |  |  |
| [gcs_buckets](outputs.tf#L33) | GCS buckets. |  |  |
| [kms_keys](outputs.tf#L38) | Cloud MKS keys. |  |  |
| [projects](outputs.tf#L43) | GCP Projects informations. |  |  |
| [vpc_network](outputs.tf#L48) | VPC network. |  |  |
| [vpc_subnet](outputs.tf#L53) | VPC subnetworks. |  |  |

<!-- END TFDOC -->
