# Shared security resources and VPC Service Controls

This stage sets up security resources and configurations which impact the whole organization, or are shared across the hierarchy to other projects and teams.

The design of this stage is fairly general, providing

- a reference example for [Cloud KMS](https://cloud.google.com/security-key-management)
- a simplified implementation of [VPC Service Controls](https://cloud.google.com/vpc-service-controls) that should work for most users

Expanding this stage to include other security-related services like Secret Manager is fairly simple by adapting the provided implementation for Cloud KMS, and leveraging the broad permissions granted on the top-level Security folder to the automation service account used here.

The following diagram illustrates the high-level design of created resources and a schema of the VPC SC design:

<p align="center">
  <img src="diagram.png" alt="Security diagram">
</p>

<!-- BEGIN TOC -->
- [Design overview and choices](#design-overview-and-choices)
  - [Cloud KMS](#cloud-kms)
  - [VPC Service Controls](#vpc-service-controls)
- [How to run this stage](#how-to-run-this-stage)
  - [Provider and Terraform variables](#provider-and-terraform-variables)
  - [Impersonating the automation service account](#impersonating-the-automation-service-account)
  - [Variable configuration](#variable-configuration)
  - [Using delayed billing association for projects](#using-delayed-billing-association-for-projects)
  - [Running the stage](#running-the-stage)
- [Customizations](#customizations)
  - [KMS keys](#kms-keys)
  - [VPC Service Controls configuration](#vpc-service-controls-configuration)
- [Notes](#notes)
- [Files](#files)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Design overview and choices

Project-level security resources are grouped into two separate projects, one per environment. This setup matches requirements we frequently observe in real life and provides enough separation without needlessly complicating operations.

Cloud KMS is configured and designed mainly to encrypt GCP resources with a [Customer-managed encryption key](https://cloud.google.com/kms/docs/cmek) but it may be used to create cryptokeys used to [encrypt application data](https://cloud.google.com/kms/docs/encrypting-application-data) too.

IAM for day to day operations is already assigned at the folder level to the security team by the previous stage, but more granularity can be added here at the project level, to grant control of separate services across environments to different actors.

### Cloud KMS

A reference Cloud KMS implementation is part of this stage, to provide a simple way of managing centralized keys, that are then shared and consumed widely across the organization to enable customer-managed encryption. The implementation is also easy to clone and modify to support other services like Secret Manager.

The Cloud KMS configuration allows defining keys by name (typically matching the downstream service that uses them) in different locations. It then takes care internally of provisioning the relevant keyrings and creating keys in the appropriate location.

IAM roles on keys can be configured at the logical level for all locations where a logical key is created. Their management can also be delegated via [delegated role grants](https://cloud.google.com/iam/docs/setting-limits-on-granting-roles) exposed through a simple variable, to allow other identities to set IAM policies on keys. This is particularly useful in setups like project factories, making it possible to configure IAM bindings during project creation for team groups or service agent accounts (compute, storage, etc.).

### VPC Service Controls

This stage also provisions the VPC Service Controls configuration that protects the whole organization, implementing a simplified design that leverages a single perimeter and optionally provides automatic enrollment of projects in the perimeter.

The VPC SC configuration is controlled via the top-level `vpc_sc` variable, and is disabled by default unless `vpc_sc.perimeter_default` is populated. Access levels and ingress/egress policies can be defined in code via the respective `vpc_sc` variable attributes, or via YAML-based factories configured via the usual `factories_config` variable.

## How to run this stage

This stage is meant to be executed after the [resource management](../1-resman) stage has run, as it leverages the automation service account and bucket created there, and additional resources configured in the [bootstrap](../0-bootstrap) stage.

It's of course possible to run this stage in isolation, but that's outside the scope of this document, and you would need to refer to the code for the previous stages for the environmental requirements.

Before running this stage, you need to make sure you have the correct credentials and permissions, and localize variables by assigning values that match your configuration.

### Provider and Terraform variables

As all other FAST stages, the [mechanism used to pass variable values and pre-built provider files from one stage to the next](../0-bootstrap/README.md#output-files-and-cross-stage-variables) is also leveraged here.

The commands to link or copy the provider and terraform variable files can be easily derived from the `stage-links.sh` script in the FAST root folder, passing it a single argument with the local output files folder (if configured) or the GCS output bucket in the automation project (derived from stage 0 outputs). The following examples demonstrate both cases, and the resulting commands that then need to be copy/pasted and run.

```bash
../../stage-links.sh ~/fast-config

# copy and paste the following commands for '2-security'

ln -s ~/fast-config/providers/2-security-providers.tf ./
ln -s ~/fast-config/tfvars/0-globals.auto.tfvars.json ./
ln -s ~/fast-config/tfvars/0-bootstrap.auto.tfvars.json ./
ln -s ~/fast-config/tfvars/1-resman.auto.tfvars.json ./
```

```bash
../../stage-links.sh gs://xxx-prod-iac-core-outputs-0

# copy and paste the following commands for '2-security'

gcloud alpha storage cp gs://xxx-prod-iac-core-outputs-0/providers/2-security-providers.tf ./
gcloud alpha storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/0-globals.auto.tfvars.json ./
gcloud alpha storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/0-bootstrap.auto.tfvars.json ./
gcloud alpha storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/1-resman.auto.tfvars.json ./
```

### Impersonating the automation service account

The preconfigured provider file uses impersonation to run with this stage's automation service account's credentials. The `gcp-devops` and `organization-admins` groups have the necessary IAM bindings in place to do that, so make sure the current user is a member of one of those groups.

### Variable configuration

Variables in this stage -- like most other FAST stages -- are broadly divided into three separate sets:

- variables which refer to global values for the whole organization (org id, billing account id, prefix, etc.), which are pre-populated via the `0-globals.auto.tfvars.json` file linked or copied above
- variables which refer to resources managed by previous stages, which are prepopulated here via the `0-bootstrap.auto.tfvars.json` and `1-resman.auto.tfvars.json` files linked or copied above
- and finally variables that optionally control this stage's behaviour and customizations, and can to be set in a custom `terraform.tfvars` file

The latter set is explained in the [Customization](#customizations) sections below, and the full list can be found in the [Variables](#variables) table at the bottom of this document.

Note that the `outputs_location` variable is disabled by default, you need to explicitly set it in your `terraform.tfvars` file if you want output files to be generated by this stage. This is a sample `terraform.tfvars` that configures it, refer to the [bootstrap stage documentation](../0-bootstrap/README.md#output-files-and-cross-stage-variables) for more details:

```tfvars
outputs_location = "~/fast-config"
```

### Using delayed billing association for projects

This configuration is possible but unsupported and only exists for development purposes, use at your own risk:

- temporarily switch `billing_account.id` to `null` in `0-globals.auto.tfvars.json`
- for each project resources in the project modules used in this stage (`dev-sec-project`, `prod-sec-project`)
  - apply using `-target`, for example
    `terraform apply -target 'module.prod-sec-project.google_project.project[0]'`
  - untaint the project resource after applying, for example
    `terraform untaint 'module.prod-sec-project.google_project.project[0]'`
- go through the process to associate the billing account with the two projects
- switch `billing_account.id` back to the real billing account id
- resume applying normally

### Running the stage

Once provider and variable values are in place and the correct user is configured, the stage can be run:

```bash
terraform init
terraform apply
```

## Customizations

### KMS keys

Cloud KMS configuration is controlled by `kms_keys`, which configures the actual keys to create, and also allows configuring their IAM bindings, labels, locations and rotation period. When configuring locations for a key, please consider the limitations each cloud product may have.

The additional `kms_restricted_admins` variable allows granting `roles/cloudkms.admin` to specified principals, restricted via [delegated role grants](https://cloud.google.com/iam/docs/setting-limits-on-granting-roles) so that it only allows granting the roles needed for encryption/decryption on keys. This allows safe delegation of key management to subsequent Terraform stages like the Project Factory, for example to grant usage access on relevant keys to the service agent accounts for compute, storage, etc.

To support these scenarios, key IAM bindings are configured by default to be additive, to enable other stages or Terraform configuration to safely co-manage bindings on the same keys. If this is not desired, follow the comments in the `core-dev.tf` and `core-prod.tf` files to switch to authoritative bindings on keys.

An example of how to configure keys:

```tfvars
# terraform.tfvars

kms_keys = {
  compute = {
    iam = {
      "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
        "user:user1@example.com"
      ]
    }
    labels          = { service = "compute" }
    locations       = ["europe-west1", "europe-west3", "global"]
    rotation_period = "7776000s"
  }
  storage = {
    iam             = null
    labels          = { service = "compute" }
    locations       = ["europe"]
    rotation_period = null
  }
}
```

The script will create one keyring for each specified location and keys on each keyring.

### VPC Service Controls configuration

The `vpc_sc` variable controls VPC-SC configuration and project auto-discovery via Cloud Asset Inventory. VPC-SC configuration can also leverage YAML factories via the `factories_config` variable. Both variables mostly pass through to the underlying [`vpc-sc` module](../../../modules/vpc-sc/), which serves as a reference for their individual types.

The `vpc_sc` variable has the following attributes:

- `access_levels`, `egress_policies`, `ingress_policies` define the corresponding objects, internally merged with any data coming from the YAML factories
- `perimeter_default` configures the single organization-wide perimeter by referencing access levels and policies by key, setting included projects, and allowing to turn on dry run mode
- `resource_discovery` controls automatic discovery of projects via Asset Inventory, and allows defining inclusion and exclusions lists

A few things to note on the default perimeter

- writer identities for sinks defined in the bootstrap stage are passed through via output files, and automatically included in an ingress policy
- the perimeter is brought up in enforced mode by default
- project discovery is turned on by default and includes all projects in the organization

The following example configures the default perimeter, with a single broad geo-based access level. Refer to the [vpc-sc module](../../../modules/vpc-sc/) for details on how to configure ingress/egress policies, and how to leverage the YAML factories. The perimeter is set to enforced mode and leverages auto discovery of projects.

The following YAML file leverages factories to configure the broad geo-based access level (the factory path can be changed via the `factories_config` variable):

```yaml
# data/vpc-sc/access-levels/geo-default.yaml
conditions:
  - regions:
      - IT
      - ES
```

```tfvars
# terraform.tfvars

vpc_sc = {
  perimeter_default = {
    access_levels = ["geo-default"]
    # dry run is disabled by default
    dry_run = true
    # resource discovery is enabled by default
  }
}
```

## Notes

Some references that might be useful in setting up this stage:

- [VPC SC CSCC requirements](https://cloud.google.com/security-command-center/docs/troubleshooting).

<!-- TFDOC OPTS files:1 show_extra:1 -->
<!-- BEGIN TFDOC -->
## Files

| name | description | modules | resources |
|---|---|---|---|
| [core-dev.tf](./core-dev.tf) | None | <code>kms</code> · <code>project</code> |  |
| [core-prod.tf](./core-prod.tf) | None | <code>kms</code> · <code>project</code> |  |
| [main.tf](./main.tf) | Module-level locals and resources. | <code>folder</code> |  |
| [outputs.tf](./outputs.tf) | Module outputs. |  | <code>google_storage_bucket_object</code> · <code>local_file</code> |
| [variables.tf](./variables.tf) | Module variables. |  |  |
| [vpc-sc.tf](./vpc-sc.tf) | None | <code>projects-data-source</code> · <code>vpc-sc</code> |  |

## Variables

| name | description | type | required | default | producer |
|---|---|:---:|:---:|:---:|:---:|
| [automation](variables.tf#L17) | Automation resources created by the bootstrap stage. | <code title="object&#40;&#123;&#10;  outputs_bucket &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>0-bootstrap</code> |
| [billing_account](variables.tf#L25) | Billing account id. If billing account is not part of the same org set `is_org_level` to false. | <code title="object&#40;&#123;&#10;  id           &#61; string&#10;  is_org_level &#61; optional&#40;bool, true&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>0-bootstrap</code> |
| [folder_ids](variables.tf#L58) | Folder name => id mappings, the 'security' folder name must exist. | <code title="object&#40;&#123;&#10;  security &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>1-resman</code> |
| [organization](variables.tf#L115) | Organization details. | <code title="object&#40;&#123;&#10;  domain      &#61; string&#10;  id          &#61; number&#10;  customer_id &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>0-bootstrap</code> |
| [prefix](variables.tf#L131) | Prefix used for resources that need unique names. Use 9 characters or less. | <code>string</code> | ✓ |  | <code>0-bootstrap</code> |
| [service_accounts](variables.tf#L141) | Automation service accounts that can assign the encrypt/decrypt roles on keys. | <code title="object&#40;&#123;&#10;  data-platform-dev    &#61; string&#10;  data-platform-prod   &#61; string&#10;  project-factory-dev  &#61; string&#10;  project-factory-prod &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  | <code>1-resman</code> |
| [essential_contacts](variables.tf#L38) | Email used for essential contacts, unset if null. | <code>string</code> |  | <code>null</code> |  |
| [factories_config](variables.tf#L44) | Paths to folders that enable factory functionality. | <code title="object&#40;&#123;&#10;  vpc_sc &#61; optional&#40;object&#40;&#123;&#10;    access_levels       &#61; optional&#40;string, &#34;data&#47;vpc-sc&#47;access-levels&#34;&#41;&#10;    egress_policies     &#61; optional&#40;string, &#34;data&#47;vpc-sc&#47;egress-policies&#34;&#41;&#10;    ingress_policies    &#61; optional&#40;string, &#34;data&#47;vpc-sc&#47;ingress-policies&#34;&#41;&#10;    restricted_services &#61; optional&#40;string, &#34;data&#47;vpc-sc&#47;restricted-services.yaml&#34;&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [kms_keys](variables.tf#L66) | KMS keys to create, keyed by name. | <code title="map&#40;object&#40;&#123;&#10;  rotation_period &#61; optional&#40;string, &#34;7776000s&#34;&#41;&#10;  labels          &#61; optional&#40;map&#40;string&#41;&#41;&#10;  locations &#61; optional&#40;list&#40;string&#41;, &#91;&#10;    &#34;europe&#34;, &#34;europe-west1&#34;, &#34;europe-west3&#34;, &#34;global&#34;&#10;  &#93;&#41;&#10;  purpose                       &#61; optional&#40;string, &#34;ENCRYPT_DECRYPT&#34;&#41;&#10;  skip_initial_version_creation &#61; optional&#40;bool, false&#41;&#10;  version_template &#61; optional&#40;object&#40;&#123;&#10;    algorithm        &#61; string&#10;    protection_level &#61; optional&#40;string, &#34;SOFTWARE&#34;&#41;&#10;  &#125;&#41;&#41;&#10;&#10;&#10;  iam &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;    members &#61; list&#40;string&#41;&#10;    role    &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;    member &#61; string&#10;    role   &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [logging](variables.tf#L105) | Log writer identities for organization / folders. | <code title="object&#40;&#123;&#10;  project_number    &#61; string&#10;  writer_identities &#61; map&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> | <code>0-bootstrap</code> |
| [outputs_location](variables.tf#L125) | Path where providers, tfvars files, and lists for the following stages are written. Leave empty to disable. | <code>string</code> |  | <code>null</code> |  |
| [vpc_sc](variables.tf#L152) | VPC SC configuration. | <code title="object&#40;&#123;&#10;  access_levels    &#61; optional&#40;map&#40;any&#41;, &#123;&#125;&#41;&#10;  egress_policies  &#61; optional&#40;map&#40;any&#41;, &#123;&#125;&#41;&#10;  ingress_policies &#61; optional&#40;map&#40;any&#41;, &#123;&#125;&#41;&#10;  perimeter_default &#61; optional&#40;object&#40;&#123;&#10;    access_levels    &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    dry_run          &#61; optional&#40;bool, false&#41;&#10;    egress_policies  &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    ingress_policies &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    resources        &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;&#41;&#10;  resource_discovery &#61; optional&#40;object&#40;&#123;&#10;    enabled          &#61; optional&#40;bool, true&#41;&#10;    ignore_folders   &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    ignore_projects  &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    include_projects &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |

## Outputs

| name | description | sensitive | consumers |
|---|---|:---:|---|
| [kms_keys](outputs.tf#L59) | KMS key ids. |  |  |
| [tfvars](outputs.tf#L72) | Terraform variable files for the following stages. | ✓ |  |
| [vpc_sc_perimeter_default](outputs.tf#L64) | Raw default perimeter resource. | ✓ |  |
<!-- END TFDOC -->
