# SecOps Stage

This stage allows automated configuration of SecOps instance at both infrastructure and application level.

The following diagram illustrates the high-level design of SecOps instance configuration in both GCP and SecOps instance, which can be adapted to specific requirements via variables.

<p align="center">
  <img src="diagram.png" alt="SecOPs stage">
</p>

<!-- BEGIN TOC -->
- [Design overview and choices](#design-overview-and-choices)
- [How to run this stage](#how-to-run-this-stage)
  - [Resource management configuration](#resource-management-configuration)
  - [Provider and Terraform variables](#provider-and-terraform-variables)
  - [Impersonating the automation service account](#impersonating-the-automation-service-account)
  - [Variable configuration](#variable-configuration)
  - [Running the stage](#running-the-stage)
- [Customizations](#customizations)
  - [Data RBAC](#data-rbac)
  - [SecOps rules and reference list management](#secops-rules-and-reference-list-management)
  - [Google Workspace integration](#google-workspace-integration)
- [Files](#files)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Design overview and choices

The general idea behind this stage is to configure a single SecOps instance for a specific environment with configurations both on SecOps leveraging terraform resources (where available) and `restful_resource` for interacting with the new [SecOps APIs](https://cloud.google.com/chronicle/docs/reference/rest).

Some high level features of the current version of the stage are:

- API/Services enablement
- Data RBAC configuration with labels and scopes
- IAM setup for the SecOps instance based on groups from Cloud Identity or WIF (with supports for Data RBAC)
- Detection Rules and reference lists management via terraform (leveraging [secops-rules](../../../modules/secops-rules) module)
- API Key setup for Webhook feeds 
- Integration with Workspace for alerts and logs ingestion via SecOps Feeds

## How to run this stage

This stage is meant to be executed after the FAST "foundational" stages: bootstrap, resource management, secops stages.

It's of course possible to run this stage in isolation, refer to the *[Running in isolation](#running-in-isolation)* section below for details.

Before running this stage, you need to make sure you have the correct credentials and permissions, and localize variables by assigning values that match your configuration.

### Resource management configuration

Some configuration changes are needed in resource management before this stage can be run.

Make sure the stage 3 is enabled in the `data/stage-3` folder [in the resource management stage](../1-resman/data/stage-3/). As an example, this YAML definition saved as `secops-dev.yaml` enables this stage 3 for the development environment:

```yaml
# yaml-language-server: $schema=../../schemas/fast-stage3.schema.json

short_name: secops
environment: dev
folder_config:
  name: Development
  parent_id: secops
```

Make sure the stage 3 definitions are aligned with the environments you would like to setup for SecOps and coherent with the environments definitions in the stage 2 [2-secops](../2-secops) in order to have a dedicated stage 3 for SecOps for each environment (dev and prod as an example).

### Provider and Terraform variables

As all other FAST stages, the [mechanism used to pass variable values and pre-built provider files from one stage to the next](../0-bootstrap/README.md#output-files-and-cross-stage-variables) is also leveraged here.

The commands to link or copy the provider and terraform variable files can be easily derived from the `fast-links.sh` script in the FAST root folder, passing it a single argument with the local output files folder (if configured) or the GCS output bucket in the automation project (derived from stage 0 outputs). The following examples demonstrate both cases, and the resulting commands that then need to be copy/pasted and run.

```bash
../fast-links.sh ~/fast-config

# File linking commands for GKE (dev) stage

# provider file
ln -s ~/fast-config/providers/3-secops-dev-providers.tf ./

# input files from other stages
ln -s ~/fast-config/tfvars/0-globals.auto.tfvars.json ./
ln -s ~/fast-config/tfvars/0-bootstrap.auto.tfvars.json ./
ln -s ~/fast-config/tfvars/1-resman.auto.tfvars.json ./
ln -s ~/fast-config/tfvars/2-secops.auto.tfvars.json ./

# conventional place for stage tfvars (manually created)
ln -s ~/fast-config/3-secops-dev.auto.tfvars ./
```

```bash
../fast-links.sh gs://xxx-prod-iac-core-outputs-0

# File linking commands for GKE (dev) stage

# provider file
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/providers/3-secops-dev-providers.tf ./

# input files from other stages
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/0-globals.auto.tfvars.json ./
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/0-bootstrap.auto.tfvars.json ./
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/1-resman.auto.tfvars.json ./
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/2-secops.auto.tfvars.json ./

# conventional place for stage tfvars (manually created)
gcloud storage cp gs://xxx-prod-iac-core-outputs-0/3-secops-dev.auto.tfvars ./
```

### Impersonating the automation service account

The preconfigured provider file uses impersonation to run with this stage's automation service account's credentials. The `gcp-devops` and `organization-admins` groups have the necessary IAM bindings in place to do that, so make sure the current user is a member of one of those groups.

### Variable configuration

Variables in this stage -- like most other FAST stages -- are broadly divided into three separate sets:

- variables which refer to global values for the whole organization (org id, billing account id, prefix, etc.), which are pre-populated via the `0-globals.auto.tfvars.json` file linked or copied above
- variables which refer to resources managed by previous stage, which are prepopulated here via the `*.auto.tfvars.json` files linked or copied above
- and finally variables that optionally control this stage's behaviour and customizations, and can to be set in a custom `terraform.tfvars` file

The latter set is explained in the [Customization](#customizations) sections below, and the full list can be found in the [Variables](#variables) table at the bottom of this document.

### Running the stage

Once provider and variable values are in place and the correct user is configured, the stage can be run:

```bash
terraform init
terraform apply
```

## Customizations

This stage is designed with few basic integrations provided out of the box which can be customized as per the following sections.

### Data RBAC

This stage supports configuration of [SecOps Data RBAC](https://cloud.google.com/chronicle/docs/administration/datarbac-overview) using two separate variables:

- `secops_data_rbac_config`: specifies Data RBAC [label and scopes](https://cloud.google.com/chronicle/docs/administration/configure-datarbac-users) in Google SecOps 
- `secops_iam`: defines SecOps IAM configuration in {PRINCIPAL => {roles => [ROLES], scopes => [SCOPES]}} format referencing previously defined scopes. When scope is populated a [IAM condition](https://cloud.google.com/chronicle/docs/administration/configure-datarbac-users#assign-scope-to-users) restrict access to those scopes.

Example of a Data RBAC configuration is reported below.

```hcl
secops_data_rbac_config = {
  labels = {
    google = {
      description = "Google logs"
      label_id    = "google"
      udm_query   = "principal.hostname=\"google.com\""
    }
  }
  scopes = {
    google = {
      description = "Google logs"
      scope_id    = "gscope"
      allowed_data_access_labels = [{
        data_access_label = "google"
      }]
    }
  }
}
secops_iam = {
  "user:bruzzechesse@google.com" = {
    roles  = ["roles/chronicle.editor"]
    scopes = ["gscope"]
  }
}
# tftest skip
```

### SecOps rules and reference list management

This stage leverages the [secops-rules](../../../modules/secops-rules) for automated SecOps rules and reference list deployment via Terraform.

By default, the stage will try to deploy sample rule and reference list available in the [rules](./data/rules) and [reference_lists](./data/reference_lists) folders according to the configuration files `secops_rules.yaml` and `secops_reference_lists.yaml`.

The configuration can be updated via the `factory_config` variable as per the `secops-rules` module [README.md](../../../modules/secops-rules/README.md).

### Google Workspace integration

The stage supports automatic integration of Google Workspace as a SecOps source leveraging [SecOps Feeds](https://cloud.google.com/chronicle/docs/ingestion/default-parsers/collect-workspace-logs#configure_a_feed_in_to_ingest_logs) integration.

Integration is enabled via the `workspace_integration_config` variable as per the following sample:

```hcl
workspace_integration_config = {
  delegated_user        = "secops-feed@..."
  workspace_customer_id = "CXXXXXXX"
}
# tftest skip
```

Where `delegated_user` should be the email of the user created in Cloud Identity following the configuration instructions available [here](https://cloud.google.com/chronicle/docs/ingestion/default-parsers/collect-workspace-logs#configure_a_feed_in_to_ingest_logs).

Please be aware the Service Account Client ID needed during domain wide delegation setup is available in the key of the service account stored in Secret Manager.

<!-- TFDOC OPTS files:1 show_extra:1 exclude:3-secops-dev-providers.tf -->
<!-- BEGIN TFDOC -->
## Files

| name | description | modules | resources |
|---|---|---|---|
| [main.tf](./main.tf) | Module-level locals and resources. | <code>project</code> · <code>secops-rules</code> | <code>google_apikeys_key</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  |  |
| [providers-override.tf](./providers-override.tf) | None |  |  |
| [secops-providers.tf](./secops-providers.tf) | None |  |  |
| [secops.tf](./secops.tf) | None |  | <code>google_chronicle_data_access_label</code> · <code>google_chronicle_data_access_scope</code> |
| [secrets.tf](./secrets.tf) | None | <code>secret-manager</code> |  |
| [variables-fast.tf](./variables-fast.tf) | None |  |  |
| [variables.tf](./variables.tf) | Module variables. |  |  |
| [workspace.tf](./workspace.tf) | None | <code>iam-service-account</code> | <code>google_service_account_key</code> · <code>restful_resource</code> |

## Variables

| name | description | type | required | default | producer |
|---|---|:---:|:---:|:---:|:---:|
| [tenant_config](variables.tf#L118) | SecOps Tenant configuration. | <code title="object&#40;&#123;&#10;  customer_id &#61; string&#10;  region      &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |  |
| [billing_account](variables-fast.tf#L17) | Billing account id. If billing account is not part of the same org set `is_org_level` to false. | <code title="object&#40;&#123;&#10;  id &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> | <code>0-bootstrap</code> |
| [data_rbac_config](variables.tf#L17) | SecOps Data RBAC scope and labels config. | <code title="object&#40;&#123;&#10;  labels &#61; optional&#40;map&#40;object&#40;&#123;&#10;    description &#61; string&#10;    label_id    &#61; string&#10;    udm_query   &#61; string&#10;  &#125;&#41;&#41;&#41;&#10;  scopes &#61; optional&#40;map&#40;object&#40;&#123;&#10;    description &#61; string&#10;    scope_id    &#61; string&#10;    allowed_data_access_labels &#61; optional&#40;list&#40;object&#40;&#123;&#10;      data_access_label &#61; optional&#40;string&#41;&#10;      log_type          &#61; optional&#40;string&#41;&#10;      asset_namespace   &#61; optional&#40;string&#41;&#10;      ingestion_label &#61; optional&#40;object&#40;&#123;&#10;        ingestion_label_key   &#61; string&#10;        ingestion_label_value &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;, &#91;&#93;&#41;&#10;    denied_data_access_labels &#61; optional&#40;list&#40;object&#40;&#123;&#10;      data_access_label &#61; optional&#40;string&#41;&#10;      log_type          &#61; optional&#40;string&#41;&#10;      asset_namespace   &#61; optional&#40;string&#41;&#10;      ingestion_label &#61; optional&#40;object&#40;&#123;&#10;        ingestion_label_key   &#61; string&#10;        ingestion_label_value &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [factories_config](variables.tf#L51) | Paths to  YAML config expected in 'rules' and 'reference_lists'. Path to folders containing rules definitions (yaral files) and reference lists content (txt files) for the corresponding _defs keys. | <code title="object&#40;&#123;&#10;  rules                &#61; optional&#40;string&#41;&#10;  rules_defs           &#61; optional&#40;string, &#34;data&#47;rules&#34;&#41;&#10;  reference_lists      &#61; optional&#40;string&#41;&#10;  reference_lists_defs &#61; optional&#40;string, &#34;data&#47;reference_lists&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  rules                &#61; &#34;.&#47;data&#47;secops_rules.yaml&#34;&#10;  rules_defs           &#61; &#34;.&#47;data&#47;rules&#34;&#10;  reference_lists      &#61; &#34;.&#47;data&#47;secops_reference_lists.yaml&#34;&#10;  reference_lists_defs &#61; &#34;.&#47;data&#47;reference_lists&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |  |
| [folder_ids](variables-fast.tf#L26) | Folder name => id mappings. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> | <code>1-resman</code> |
| [iam](variables.tf#L68) | SecOps IAM configuration in {PRINCIPAL => {roles => [ROLES], scopes => [SCOPES]}} format. | <code title="map&#40;object&#40;&#123;&#10;  roles  &#61; list&#40;string&#41;&#10;  scopes &#61; optional&#40;list&#40;string&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [iam_default](variables.tf#L78) | Groups ID in IdP assigned to SecOps admins, editors, viewers roles. | <code title="object&#40;&#123;&#10;  admins  &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  editors &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  viewers &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [project_id](variables.tf#L88) | Project id that references existing SecOps project. Use this variable when running this stage in isolation. | <code>string</code> |  | <code>null</code> |  |
| [project_reuse](variables.tf#L94) | Whether to use an existing project, leave default for FAST deployment. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [region](variables.tf#L100) | Google Cloud region definition for resources. | <code>string</code> |  | <code>&#34;europe-west8&#34;</code> |  |
| [secops_project_ids](variables-fast.tf#L34) | SecOps Project IDs for each environment. | <code>map&#40;string&#41;</code> |  | <code>null</code> | <code>2-secops</code> |
| [stage_config](variables.tf#L106) | FAST stage configuration used to find resource ids. Must match name defined for the stage in resource management. | <code title="object&#40;&#123;&#10;  environment &#61; string&#10;  name        &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  environment &#61; &#34;dev&#34;&#10;  name        &#61; &#34;secops-dev&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |  |
| [workspace_integration_config](variables.tf#L126) | SecOps Feeds configuration for Workspace logs and entities ingestion. | <code title="object&#40;&#123;&#10;  workspace_customer_id &#61; string&#10;  delegated_user        &#61; string&#10;  applications &#61; optional&#40;list&#40;string&#41;, &#91;&#34;access_transparency&#34;, &#34;admin&#34;, &#34;calendar&#34;, &#34;chat&#34;, &#34;drive&#34;, &#34;gcp&#34;,&#10;    &#34;gplus&#34;, &#34;groups&#34;, &#34;groups_enterprise&#34;, &#34;jamboard&#34;, &#34;login&#34;, &#34;meet&#34;, &#34;mobile&#34;, &#34;rules&#34;, &#34;saml&#34;, &#34;token&#34;,&#10;    &#34;user_accounts&#34;, &#34;context_aware_access&#34;, &#34;chrome&#34;, &#34;data_studio&#34;, &#34;keep&#34;,&#10;  &#93;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |  |

## Outputs

| name | description | sensitive | consumers |
|---|---|:---:|---|
| [project_id](outputs.tf#L15) | SecOps project id. |  |  |
<!-- END TFDOC -->
