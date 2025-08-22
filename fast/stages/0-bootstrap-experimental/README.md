# FAST Light Bootstrap (Experimental)

<!-- BEGIN TOC -->
- [Quickstart](#quickstart)
  - [Prerequisites](#prerequisites)
  - [Defaults configuration](#defaults-configuration)
  - [Stage configuration](#stage-configuration)
  - [Initial user configuration and first apply cycle](#initial-user-configuration-and-first-apply-cycle)
  - [Impersonation set-up and final apply cycle](#impersonation-set-up-and-final-apply-cycle)
- [Detailed configuration](#detailed-configuration)
  - [Factory data](#factory-data)
  - [Defaults configuration](#defaults-configuration)
  - [Billing account IAM](#billing-account-iam)
    - [Context-based replacement in the billing account factory](#context-based-replacement-in-the-billing-account-factory)
  - [Organization configuration](#organization-configuration)
    - [Context-based replacement in organization factories](#context-based-replacement-in-organization-factories)
  - [Resource management hierarchy](#resource-management-hierarchy)
    - [Context-based replacement in the folders factory](#context-based-replacement-in-the-folders-factory)
  - [Project factory](#project-factory)
  - [CI/CD configuration](#cicd-configuration)
- [Leveraging classic FAST Stages](#leveraging-classic-fast-stages)
  - [VPC Service Controls](#vpc-service-controls)
  - [Security](#security)
- [Files](#files)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

This stage implements a flexible approach to organization bootstrapping and resource management, that offers full customization via YAML factories.

It heavily relies on a new [project factory module](../../../modules/project-factory-experimental/) for folder and project configurations, and leverages a new approach to [context-based interpolation](../../../modules/project-factory-experimental/README.md#context-based-interpolation) that allows writing legible, portable YAML definitions.

The default set of YAML configuration files in the `data` folder mirrors the traditional FAST layout, and implements full compatibility with existing FAST stages like VPC-SC, security, networking, etc.

The default configuration can be used as a starting point to implement radically different Landing Zone designs, or trimmed down to its bare minimum where the requirements are simply to have a secure organization-level configuration (possibly with VPC-SC), and a working project factory.

## Quickstart

The high-level flow for running this stage is:

- ensure all pre-requisites are in place, and identify at least one GCP organization admin principal (ideally a group)
- populate the defaults file with attributes matching your configuration (organization id, billing account, etc.)
- select the configuration data set among those available (`data`, `data-minimal`, etc.) or edit/create your own
- assign a set of initial role to the admin principal
- run a first init/apply cycle using user credentials
- migrate state, then run a second init/apply cycle using impersonated credentials of the generated service account

### Prerequisites

### Defaults configuration

### Stage configuration

### Initial user configuration and first apply cycle

### Impersonation set-up and final apply cycle

## Detailed configuration

The following sections explain how to configure and run this stage, and should be read in sequence when using it for the first time.

### Factory data

The resources created by this stage are controlled by several factories, which point to YAML configuration files and folders. Data locations for each factory are controlled via the `var.factories_config` variable, and each factory path can be overridden individually.

The default paths point to the dataset in the `data` folder which deploys a FAST-compliant configuration. These are the available factories in this stage, with file-level factories based on a single YAML file, and folder-level factories based on sets of YAML files contained withing a filesystem folder:

- **defaults** (`data/defaults.yaml`) \
  file-level factory to define stage defaults (organization id, locations, prefix, etc.) and static context mappings
- **billing_accounts** (`data/billing-accounts`) \
  folder-level factory where each YAML file defines billing-account level IAM for one billing account; only used for externally managed accounts
- **organization** (`data/organization/.config.yaml`) \
  file-level factory to define organization IAM and log sinks
  - **custom roles** (`data/organization/custom-roles`) \
    folder-level factory to define organization-level custom roles
  - **org policies** (`data/organization/org-policies`) \
    folder-level factory to define organization-level org policies
  - **tags** (`data/organization/tags`) \
    folder-level factory to define organization-level resource management tags
- **folders** (`data/folders`) \
  folder-level factory to define the resource management hierarchy and individual folder attributes (IAM, org policies, tag bindings, etc.); also supports defining folder-level IaC resources
- **projects** (`data/projects`) \
  folder-level factory to define projects and their attributes (projejct factory)
- **cicd** (`data/cicd.yaml`) \
  file-level factory to define CI/CD configurations for this and subsequent stages

### Defaults configuration

The prerequisite configuration for this stage is done via a `defaults.yaml` file, which implements part or all of the [relevant JSON schema](./schemas/defaults.schema.json). The location of the file defaults to `data/defaults.yaml` but can be easily changed via the `factories_config.defaults` variable.

This is a commented example of a defaults file, showing a minimal working configuration. Refer to the YAML schema for all available options.

```yaml
# global defaults used by bootstrap and persisted in the globals output file
global:
  # billing account also set as default in the internal project factory
  billing_account: 123456-123456-123456
  # default locations for this stage resources
  locations:
    bigquery: europe-west1
    logging: europe-west1
  # organization attributes (id is required)
  organization:
    domain: example.org
    id: 1234567890
    customer_id: ABC0123CDE
# project defaults and overrides used by the internal project factory
projects:
  defaults:
    # setting a prefix either here or in overrides is required
    prefix: foo-1
    # default location for storage buckets
    storage_location: europe-west1
  overrides: {}
# FAST output files generated by this stage
output_files:
  # optional path for locally persisted output files
  local_path: ~/fast-config/foo-1
  # required storage bucket for output files (supports context interpolation)
  storage_bucket: $storage_buckets:iac-0/iac-outputs
  # FAST stage provider files (supports context interpolation)
  providers:
    0-bootstrap:
      bucket: $storage_buckets:iac-0/iac-bootstrap-state
      service_account: $iam_principals:service_accounts/iac-0/iac-bootstrap-rw
    # [...]
# static values added to context interpolation tables and used in factories
context:
  iam_principals:
    gcp-organization-admins: group:fabric-fast-owners@example.com
```

### Billing account IAM

FAST traditionally supports three different billing configurations:

- billing account in the same organization, where billing IAM is set via organization-level bindings
- external billing account, where billing IAM is set via account-level bindings
- no billing IAM, where FAST assumes bindings are managed by some externally defined process

This stage allows the same flexibility, and even makes it possible to mix and match approaches by making billing IAM explicit:

- if billing-account level IAM bindings are needed, they can be set via the billing account factory
- if organization-level IAM bindings are needed, they can be set via the organization factory
- if no billing IAM can be managed here, it's enough to disable the billing account factory by pointing it to an empty or non-existent filesystem folder

The default dataset assumes an externally managed billing account is used, and configures its IAM accordingly via the billing account factory. The example below shows some of the IAM bindings configured at the billing account level, and how context-based interpolation is used there.

<details>
<summary>Context-based replacement examples for the billing acccounts factory</summary>

#### Context-based replacement in the billing account factory

Principal expansion leverages the `$iam_principals:` context, which is populated from the static mappings defined in defaults, and the service accounts generated via the internal project factory [described in a later section](#projects).

```yaml
# example billing account factory file
# file: billing-accounts/default.yaml
id: $defaults:billing_account
iam_bindings_additive:
  billing_admin_org_admins:
    role: roles/billing.admin
    # statically defined principal (via defaults.yaml)
    member: $iam_principals:gcp-organization-admins
  billing_admin_bootstrap_sa:
    role: roles/billing.admin
    # internally managed principal (project factory service account)
    member: $iam_principals:service_accounts/iac-0/iac-bootstrap-rw
```

</details>

### Organization configuration

The default dataset implements a classic FAST design, re-creating the required custom roles, IAM bindings, org policies, tags, and log sinks via the factories described in a previous section.

Compared to classic FAST this approach makes org-level configuration explicit, allowing easy customization of IAM and all other attributes. Before running this stage, check that the data files match your expected design.

Context-based interpolation is heavily used in the organization configuration files to refer to external or project-level resources, so as to make the factory files portable. Some examples are provided below to better illustrate usage and facilitate editing organization-level data.

<details>
<summary>Context-based replacement examples for organization factories</summary>

#### Context-based replacement in organization factories

Principal expansion leverages the `$iam_principals:` context, which is populated from the static mappings defined in defaults, and the service accounts generated via the internal project factory [described in a later section](#projects).

```yaml
# example principal-level context interpolation
# file: data/organization/.config.yaml
iam_by_principals:
  # statically defined principal (via defaults.yaml)
  $iam_principals:gcp-organization-admins:
    - roles/cloudasset.owner
    - roles/cloudsupport.admin
    - roles/compute.osAdminLogin
    # [...]
  # internally managed principal (project factory service account)
  $iam_principals:service_accounts/iac-0/iac-bootstrap-rw:
    - roles/accesscontextmanager.policyAdmin
    - roles/cloudasset.viewer
    - roles/essentialcontacts.admin
    # [...]
```

Log sinks can refer to project-level destination via different contexts.

```yaml
# example log sinks showing different destination contexts
# file: data/organization/.config.yaml
logging:
  storage_location: $locations:default
  sinks:
    # log bucket destination
    audit-logs:
      destination: $log_buckets:log-0/audit-logs
      filter: |
        log_id("cloudaudit.googleapis.com/activity") OR
        log_id("cloudaudit.googleapis.com/system_event") OR
        log_id("cloudaudit.googleapis.com/policy") OR
        log_id("cloudaudit.googleapis.com/access_transparency")
    # storage bucket destination
    iam:
      destination: $storage_buckets:log-0/iam-sink
      filter: |
        protoPayload.serviceName="iamcredentials.googleapis.com" OR
        protoPayload.serviceName="iam.googleapis.com" OR
        protoPayload.serviceName="sts.googleapis.com"
    # project destination
    vpc-sc:
      destination: $projject_ids:log-0
      filter: |
        protoPayload.metadata.@type="type.googleapis.com/google.cloud.audit.VpcServiceControlAuditMetadata"
```

Context-based expansion is not limited to the organization's `.config.yaml` file, but is also available in the other factories, like in this example for the organization-level tag factory.

```yaml
# example usage of context interpolation in tag values IAM
# file: data/organization/tags/environment.yaml
description: "Organization-level environments."
values:
  development:
    description: "Development."
    iam:
      "roles/resourcemanager.tagUser":
        - $iam_principals:service_accounts/iac-0/iac-networking-rw
        - $iam_principals:service_accounts/iac-0/iac-security-rw
        - $iam_principals:service_accounts/iac-0/iac-pf-rw
      "roles/resourcemanager.tagViewer":
        - $iam_principals:service_accounts/iac-0/iac-networking-ro
        - $iam_principals:service_accounts/iac-0/iac-security-ro
        - $iam_principals:service_accounts/iac-0/iac-pf-ro
  # [...]
```

An exception to the namespaced-based context replacements is in IAM conditions, where Terraform limitations force use of native string templating, as in the example below.

```yaml
iam_bindings:
  pf_org_policy_admin:
    role: roles/orgpolicy.policyAdmin
    members:
      - $iam_principals:service_accounts/iac-0/iac-pf-rw
    condition:
      # $organization is set as a string template variable by the module
      expression: resource.matchTag('${organization}/context', 'project-factory')
      title: Project factory org policy admin
```

</details>

### Resource management hierarchy

The folder hierarchy is managed via a filesystem tree of YAML configuration files, and leverages the [project factory module](../../../modules/project-factory-experimental/README.md#folder-hierarchy) implementation, which supports up to 3 levels of folders (4 or more can be easily implemented in the module if needed). The module documentation provides additional information on this factory usage and formats.

The default dataset implements a classic FAST layout, with top-level folders for stage 2 and stage 3, and can be easily tweaked by adding or removing any needed folder.

```bash
data/folders
├── networking
│   ├── .config.yaml
│   ├── dev
│   │   └── .config.yaml
│   └── prod
│       └── .config.yaml
├── security
│   └── .config.yaml
└── teams
    └── .config.yaml
```

Different layouts are very easy to implement by simply modeling the desired hierarchy in the filesystem, and configuring each folder via `.config.yaml` files.

The project factory also supports embedding folder-aware project definitions in folders, but that approach is best used with caution to prevent potential race conditions when moving or deleting folders and projects.

As with the factories described above, context replacements can be used in folder configurations. Some examples are provided below.

<details>
<summary>Context-based replacement examples for the folder factory</summary>

#### Context-based replacement in the folders factory

As with other examples before, the main use case is to infer IAM principals from either the static or internally defined context. One additional context which is often useful here is tag values, which allows defining a scope for organization-level conditional IAM bindings or org policies.

```yaml
# file: data/folders/teams/.config.yaml
name: Teams
iam_by_principals:
  $iam_principals:service_accounts/iac-0/iac-pf-rw:
    - roles/owner
    - roles/resourcemanager.folderAdmin
    # [...]
tag_bindings:
  context: $tag_values:context/project-factory
```

</details>

### Project factory

The projject factory is managed via a set of YAML configuration files, which like folders leverages the [project factory module](../../../modules/project-factory-experimental/README.md#folder-hierarchy) implementation. The module documentation provides additional information on this factory usage and formats.

The default dataset implements a classic FAST layout, with two top-level projects for log exports and IaC resources. Those projects can easily be changed, for example rooting them in a folder by specifying the folder id or context name in their `parent` attribute.

The provided project configurations also create several key resources for the stage like log buckets, storage buckets, and service accounts.

### CI/CD configuration

## Leveraging classic FAST Stages

### VPC Service Controls

```yaml
from:
  access_levels:
    - "*"
  identities:
    - $identity_sets:logging_identities
to:
  operations:
    - service_name: "*"
  resources:
    - $project_numbers:log-0
```

### Security

Define environments.

<!-- TFDOC OPTS files:1 -->
<!-- BEGIN TFDOC -->
## Files

| name | description | modules | resources |
|---|---|---|---|
| [billing.tf](./billing.tf) | None | <code>billing-account</code> |  |
| [cicd.tf](./cicd.tf) | None |  | <code>google_iam_workload_identity_pool</code> · <code>google_iam_workload_identity_pool_provider</code> · <code>google_storage_bucket_object</code> · <code>local_file</code> |
| [factory.tf](./factory.tf) | None | <code>project-factory-experimental</code> |  |
| [main.tf](./main.tf) | Module-level locals and resources. |  | <code>terraform_data</code> |
| [organization.tf](./organization.tf) | None | <code>organization</code> |  |
| [output-files.tf](./output-files.tf) | None |  | <code>google_storage_bucket_object</code> · <code>local_file</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  |  |
| [variables.tf](./variables.tf) | Module variables. |  |  |
| [wif-definitions.tf](./wif-definitions.tf) | Workload Identity provider definitions. |  |  |

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [bootstrap_user](variables.tf#L17) | Email of the nominal user running this stage for the first time. | <code>string</code> |  | <code>null</code> |
| [context](variables.tf#L23) | Context-specific interpolations. | <code title="object&#40;&#123;&#10;  custom_roles          &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  folder_ids            &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  iam_principals        &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  locations             &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  kms_keys              &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  notification_channels &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  project_ids           &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  service_account_ids   &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  tag_keys              &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  tag_values            &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  vpc_host_projects     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  vpc_sc_perimeters     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [factories_config](variables.tf#L43) | Configuration for the resource factories or external data. | <code title="object&#40;&#123;&#10;  billing_accounts &#61; optional&#40;string, &#34;data&#47;billing-accounts&#34;&#41;&#10;  cicd             &#61; optional&#40;string, &#34;data&#47;cicd.yaml&#34;&#41;&#10;  defaults         &#61; optional&#40;string, &#34;data&#47;defaults.yaml&#34;&#41;&#10;  folders          &#61; optional&#40;string, &#34;data&#47;folders&#34;&#41;&#10;  organization     &#61; optional&#40;string, &#34;data&#47;organization&#34;&#41;&#10;  projects         &#61; optional&#40;string, &#34;data&#47;projects&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [iam_principals](outputs.tf#L17) | IAM principals. |  |
| [locations](outputs.tf#L22) | Default locations. |  |
| [projects](outputs.tf#L27) | Attributes for managed projects. |  |
<!-- END TFDOC -->
