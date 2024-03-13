# GCVE Private Cloud for Dev Application Environment

This module enables the creation and management of a single-region GCVE Private Cloud connected to an existing network infrastructure that needs to be deployed beforehand through the rispective Fabric FAST stage. It's designed to be replicated once for every context, either per environment, regional segregation or with more granularity as needed (e.g. teams or sets of teams sharing similar requirements). 

<p align="center">
  <img src="diagram.png" alt="GCVE Private Cloud">
</p>

## Design overview and choices

> A more comprehensive description of the GCVE architecture and approach can be found in the [GCVE Single Region blueprint](../../../../blueprints/gcve/single-region-pc/). The blueprint is wrapped and configured here to leverage the FAST flow.

The GCVE stage creates a project and all the expected resources in a well-defined context, usually an ad-hoc folder managed by the resource management stage. Resources are organized by environment within this folder.


## How to run this stage

This stage is meant to be executed after the FAST "foundational" stages: bootstrap, resource management, security and networking stages.

It's of course possible to run this stage in isolation, refer to the *[Running in isolation](#running-in-isolation)* section below for details.

Before running this stage, you need to make sure you have the correct credentials and permissions, and localize variables by assigning values that match your configuration.

### Provider and Terraform variables

As all other FAST stages, the [mechanism used to pass variable values and pre-built provider files from one stage to the next](../../0-bootstrap/README.md#output-files-and-cross-stage-variables) is also leveraged here.

The commands to link or copy the provider and terraform variable files can be easily derived from the `stage-links.sh` script in the FAST root folder, passing it a single argument with the local output files folder (if configured) or the GCS output bucket in the automation project (derived from stage 0 outputs). The following examples demonstrate both cases, and the resulting commands that then need to be copy/pasted and run.

```bash
../../../stage-links.sh ~/fast-config

# copy and paste the following commands for '3-gcve'

ln -s ~/fast-config/providers/3-gcve-dev-providers.tf ./
ln -s ~/fast-config/tfvars/0-globals.auto.tfvars.json ./
ln -s ~/fast-config/tfvars/0-bootstrap.auto.tfvars.json ./
ln -s ~/fast-config/tfvars/1-resman.auto.tfvars.json ./
ln -s ~/fast-config/tfvars/2-networking.auto.tfvars.json ./
```

```bash
../../../stage-links.sh gs://xxx-prod-iac-core-outputs-0

# copy and paste the following commands for '3-gcve'

gcloud alpha storage cp gs://xxx-prod-iac-core-outputs-0/providers/3-gcve-dev-providers.tf ./
gcloud alpha storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/0-globals.auto.tfvars.json ./
gcloud alpha storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/0-bootstrap.auto.tfvars.json ./
gcloud alpha storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/1-resman.auto.tfvars.json ./
gcloud alpha storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/2-networking.auto.tfvars.json ./
```

### Impersonating the automation service account

The preconfigured provider file uses impersonation to run with this stage's automation service account's credentials. The `gcp-devops` and `organization-admins` groups have the necessary IAM bindings in place to do that, so make sure the current user is a member of one of those groups.

### Variable configuration

Variables in this stage -- like most other FAST stages -- are broadly divided into three separate sets:

- variables which refer to global values for the whole organization (org id, billing account id, prefix, etc.), which are pre-populated via the `0-globals.auto.tfvars.json` file linked or copied above
- variables which refer to resources managed by previous stage, which are prepopulated here via the `*.auto.tfvars.json` files linked or copied above
- and finally variables that optionally control this stage's behaviour and customizations, and can to be set in a custom `terraform.tfvars` file

The full list can be found in the [Variables](#variables) table at the bottom of this document.

### Running the stage

Once provider and variable values are in place and the correct user is configured, the stage can be run:

```bash
terraform init
terraform apply
```

### Running in isolation

This stage can be run in isolation by providing the necessary variables, but it's really meant to be used as part of the FAST flow after the "foundational stages" ([`0-bootstrap`](../../0-bootstrap), [`1-resman`](../../1-resman), [`2-networking`](../../2-networking-b-vpn).

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

<!-- TFDOC OPTS files:1 show_extra:1 -->
<!-- BEGIN TFDOC -->
## Files

| name | description | modules | resources |
|---|---|---|---|
| [3-gcve-prod-providers.tf](./3-gcve-prod-providers.tf) | None |  |  |
| [main.tf](./main.tf) | GCVE private cloud for development environment. | <code>single-region-pc</code> |  |
| [outputs.tf](./outputs.tf) | Output variables. |  | <code>google_storage_bucket_object</code> · <code>local_file</code> |
| [variables.tf](./variables.tf) | Module variables. |  |  |

## Variables

| name | description | type | required | default | producer |
|---|---|:---:|:---:|:---:|:---:|
| [automation](variables.tf#L17) | Automation resources created by the bootstrap stage. | <code title="object&#40;&#123;&#10;  outputs_bucket &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>0-bootstrap</code> |
| [billing_account](variables.tf#L25) | Billing account id. If billing account is not part of the same org set `is_org_level` to false. | <code title="object&#40;&#123;&#10;  id           &#61; string&#10;  is_org_level &#61; optional&#40;bool, true&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>0-bootstrap</code> |
| [folder_ids](variables.tf#L38) | Folders to be used for the networking resources in folders/nnnnnnnnnnn format. If null, folder will be created. | <code title="object&#40;&#123;&#10;  gcve-prod &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>1-resman</code> |
| [organization](variables.tf#L79) | Organization details. | <code title="object&#40;&#123;&#10;  domain      &#61; string&#10;  id          &#61; number&#10;  customer_id &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>00-globals</code> |
| [prefix](variables.tf#L95) | Prefix used for resources that need unique names. Use 9 characters or less. | <code>string</code> | ✓ |  | <code>0-bootstrap</code> |
| [private_cloud_config](variables.tf#L123) | The VMware private cloud configurations. The key is the unique private cloud name suffix. | <code title="object&#40;&#123;&#10;  cidr &#61; string&#10;  zone &#61; string&#10;  additional_cluster_configs &#61; optional&#40;map&#40;object&#40;&#123;&#10;    custom_core_count &#61; optional&#40;number&#41;&#10;    node_count        &#61; optional&#40;number, 3&#41;&#10;    node_type_id      &#61; optional&#40;string, &#34;standard-72&#34;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  management_cluster_config &#61; optional&#40;object&#40;&#123;&#10;    custom_core_count &#61; optional&#40;number&#41;&#10;    name              &#61; optional&#40;string, &#34;mgmt-cluster&#34;&#41;&#10;    node_count        &#61; optional&#40;number, 3&#41;&#10;    node_type_id      &#61; optional&#40;string, &#34;standard-72&#34;&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  description &#61; optional&#40;string, &#34;Managed by Terraform.&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |  |
| [vpc_self_links](variables.tf#L114) | Self link for the shared VPC. | <code title="object&#40;&#123;&#10;  prod-spoke-0 &#61; string&#10;  prod-landing &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>2-networking</code> |
| [group_iam](variables.tf#L59) | Project-level authoritative IAM bindings for groups in {GROUP_EMAIL => [ROLES]} format. Use group emails as keys, list of roles as values. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [groups_gcve](variables.tf#L46) | GCVE groups. | <code title="object&#40;&#123;&#10;  gcp-gcve-admin   &#61; string&#10;  gcp-gcve-viewers &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  gcp-gcve-admin   &#61; &#34;gcp-gcve-admin&#34;&#10;  gcp-gcve-viewers &#61; &#34;gcp-gcve-viewers&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |  |
| [iam](variables.tf#L66) | Project-level authoritative IAM bindings for users and service accounts in  {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [labels](variables.tf#L73) | Project-level labels. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [outputs_location](variables.tf#L89) | Path where providers, tfvars files, and lists for the following stages are written. Leave empty to disable. | <code>string</code> |  | <code>null</code> |  |
| [project_services](variables.tf#L107) | Additional project services to enable. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |  |

## Outputs

| name | description | sensitive | consumers |
|---|---|:---:|---|
| [project_id](outputs.tf#L57) | GCVE project id. |  |  |
| [vmw_engine_network_config](outputs.tf#L62) | VMware engine network configuration. |  |  |
| [vmw_engine_network_peerings](outputs.tf#L67) | The peerings created towards the user VPC or other VMware engine networks. |  |  |
| [vmw_engine_private_clouds](outputs.tf#L72) | VMware engine private cloud resources. |  |  |
<!-- END TFDOC -->
