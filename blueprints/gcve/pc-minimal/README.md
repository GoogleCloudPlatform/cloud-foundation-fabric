# Minimal GCVE Private Cloud

This stage implements an opinionated architecture to handle different Google VMware Engine deployment scenarios: from a simple single region Private Cloud to multi-region Private Clouds spread across different locations.

The general approach used here is to deploy a single project hosting one or more GCVE Private Clouds, connected to a shared VMware Engine Network (VEN). Peerings to existing VPC networks can also be configured.

Multiple deployments of this stage allow implementig more complex designs, for example using multiple projects for different Private Clouds, or connections to independent VMWare Engine Networks.

Like any other FAST stage, this can be used as a standalone deployment provided the [minimum prerequisites](#running-in-isolation) are met. This is the base diagram of the resources deployed via this stage.

<p align="center">
  <img src="diagram.png" alt="GCVE single region Private Cloud">
</p>

## Table of contents

<!-- BEGIN TOC -->

## Design overview and choices

This stage implements GCP best practices for using GCVE in a simple (but easily extensible) scenario. Refer to the [GCVE documentation](https://cloud.google.com/vmware-engine/docs/overview) for an in depth overview.

## How to run this stage

This stage is meant to be executed after the FAST "foundational" stages: bootstrap, resource management and networking.

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

gcloud storage cp gs://xxx-prod-iac-core-outputs-0/providers/3-gcve-dev-providers.tf ./
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/0-globals.auto.tfvars.json ./
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/0-bootstrap.auto.tfvars.json ./
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/1-resman.auto.tfvars.json ./
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/2-networking.auto.tfvars.json ./
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

This stage can be run in isolation by providing the necessary variables, but it's really meant to be used as part of the FAST flow after the "foundational stages" ([`0-bootstrap`](../../0-bootstrap), [`1-resman`](../../1-resman), [`2-networking`](../../2-networking-a-simple).

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

<!-- TFDOC OPTS files:1 -->
<!-- BEGIN TFDOC -->
## Files

| name | description | modules | resources |
|---|---|---|---|
| [gcve-pc.tf](./gcve-pc.tf) | GCVE Private Cloud. | <code>gcve-private-cloud</code> | <code>google_vmwareengine_network_peering</code> |
| [main.tf](./main.tf) | Project. | <code>project</code> |  |
| [output.tf](./output.tf) | Output variables. |  |  |
| [variables.tf](./variables.tf) | Module variables. |  |  |

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [billing_account_id](variables.tf#L17) | Billing account ID. | <code>string</code> | ✓ |  |
| [folder_id](variables.tf#L22) | Folder used for the GCVE project in folders/nnnnnnnnnnn format. | <code>string</code> | ✓ |  |
| [groups](variables.tf#L27) | GCVE groups. | <code title="object&#40;&#123;&#10;  gcp-gcve-admins  &#61; string&#10;  gcp-gcve-viewers &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [prefix](variables.tf#L81) | Prefix used for resource names. | <code>string</code> | ✓ |  |
| [private_cloud_configs](variables.tf#L90) | The VMware Private Cloud configurations. The key is the unique Private Cloud name suffix. | <code title="map&#40;object&#40;&#123;&#10;  cidr &#61; string&#10;  zone &#61; string&#10;  additional_cluster_configs &#61; optional&#40;map&#40;object&#40;&#123;&#10;    custom_core_count &#61; optional&#40;number&#41;&#10;    node_count        &#61; optional&#40;number, 3&#41;&#10;    node_type_id      &#61; optional&#40;string, &#34;standard-72&#34;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  management_cluster_config &#61; optional&#40;object&#40;&#123;&#10;    custom_core_count &#61; optional&#40;number&#41;&#10;    name              &#61; optional&#40;string, &#34;mgmt-cluster&#34;&#41;&#10;    node_count        &#61; optional&#40;number, 3&#41;&#10;    node_type_id      &#61; optional&#40;string, &#34;standard-72&#34;&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  description &#61; optional&#40;string, &#34;Managed by Terraform.&#34;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> | ✓ |  |
| [project_id](variables.tf#L112) | ID of the project that will contain the GCVE Private Cloud. | <code>string</code> | ✓ |  |
| [iam](variables.tf#L36) | Project-level authoritative IAM bindings for users and service accounts in  {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_by_principals](variables.tf#L43) | Authoritative IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid cycle errors. Merged internally with the `iam` variable. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [labels](variables.tf#L50) | Project-level labels. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [network_peerings](variables.tf#L56) | The network peerings between users' VPCs and the VMware Engine networks. The key is the peering name suffix. | <code title="map&#40;object&#40;&#123;&#10;  peer_network           &#61; string&#10;  configure_peer_network &#61; optional&#40;bool, false&#41;&#10;  custom_routes &#61; optional&#40;object&#40;&#123;&#10;    export_to_peer   &#61; optional&#40;bool, false&#41;&#10;    import_from_peer &#61; optional&#40;bool, false&#41;&#10;    export_to_ven    &#61; optional&#40;bool, false&#41;&#10;    import_from_ven  &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  custom_routes_with_public_ip &#61; optional&#40;object&#40;&#123;&#10;    export_to_peer   &#61; optional&#40;bool, false&#41;&#10;    import_from_peer &#61; optional&#40;bool, false&#41;&#10;    export_to_ven    &#61; optional&#40;bool, false&#41;&#10;    import_from_ven  &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  description                   &#61; optional&#40;string, &#34;Managed by Terraform.&#34;&#41;&#10;  peer_project_id               &#61; optional&#40;string&#41;&#10;  peer_to_vmware_engine_network &#61; optional&#40;bool, false&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [project_services](variables.tf#L117) | Additional project services to enable. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
<!-- END TFDOC -->
