# Project and Folder Factory

This module implements end-to-end creation processes for a folder hierarchy,   projects and billing budgets via YAML data configurations.

It supports

- filesystem-driven folder hierarchy exposing the full configuration options available in the [folder module](../folder/)
- multiple project creation and management exposing the full configuration options available in the [project module](../project/), including KMS key grants and VPC-SC perimeter membership
- optional per-project [service account and bucket management](#service-accounts-and-buckets) including basic IAM grants
- optional [billing budgets](#billing-budgets) factory and budget/project associations
- cross-referencing of hierarchy folders in projects
- optional per-project IaC configuration

The factory is implemented as a thin data translation layer for the underlying modules, so that no "magic" or hidden side effects are implemented in code, and debugging or integration of new features are simple.

The code is meant to be executed by a high level service accounts with powerful permissions:

- folder admin permissions for the hierarchy
- project creation on the nodes (folder or org) where projects will be defined
- Shared VPC connection if service project attachment is desired
- billing cost manager permissions to manage budgets and monitoring permissions if notifications should also be managed here

## Contents

<!-- BEGIN TOC -->
- [Folder hierarchy](#folder-hierarchy)
- [Projects](#projects)
  - [Factory-wide project defaults, merges, optionals](#factory-wide-project-defaults-merges-optionals)
  - [Service accounts and buckets](#service-accounts-and-buckets)
  - [Automation project and resources](#automation-project-and-resources)
- [Billing budgets](#billing-budgets)
- [Interpolation in YAML configuration attributes](#interpolation-in-yaml-configuration-attributes)
- [Example](#example)
- [Files](#files)
- [Variables](#variables)
- [Outputs](#outputs)
- [Tests](#tests)
<!-- END TOC -->

## Folder hierarchy

The hierarchy supports up to three levels of folders, which are defined via filesystem directories each including a `_config.yaml` files detailing their attributes.

The hierarchy factory is configured via the `factories_config.folders_data_path` variable, which sets the the path containing the YAML definitions for folders.

Parent ids for top-level folders can either be set explicitly (e.g. `folders/12345678`) or via substitutions, by referring to keys in the `context.folder_ids` variable. The special `default` key in the substitutions folder variable is used if present and no folder id/key has been specified in the YAML.

Filesystem directories can also contain project definitions in the same YAML format described below. This approach must be used with caution and is best adopted for stable scenarios, as problems in the filesystem hierarchy definitions might result in the project files not being read and the resources being deleted by Terraform.

Refer to the [example](#example) below for actual examples of the YAML definitions.

## Projects

The project factory is configured via the `factories_config.projects_data_path` variable, and project files are also read from the hierarchy describe in the previous section when enabled. The YAML format mirrors the project module, refer to the [example](#example) below for actual examples of the YAML definitions.

### Factory-wide project defaults, merges, optionals

In addition to the YAML-based project configurations, the factory accepts three additional sets of inputs via Terraform variables:

- the `data_defaults` variable allows defining defaults for specific project attributes, which are only used if the attributes are not passed in via YAML
- the `data_overrides` variable works similarly to defaults, but the values specified here take precedence over those in YAML files
- the `data_merges` variable allows specifying additional values for map or set based variables, which are merged with the data coming from YAML

Some examples on where to use each of the three sets are [provided below](#example).

### Service accounts and buckets

Service accounts and GCS buckets can be managed as part of each project's YAML configuration. This allows creation of default service accounts used for GCE instances, in firewall rules, or for application-level credentials without resorting to a separate Terraform configuration.

Each service account is represented by one key and a set of optional key/value pairs in the `service_accounts` top-level YAML map, which exposes most of the variables available in the `iam-service-account` module. Both the `display_name` and `iam_self_roles` attributes are optional.

```yaml
service_accounts:
  be-0: {}
  fe-1:
    display_name: GCE frontend service account.
    iam_self_roles:
      - roles/storage.objectViewer
    iam_project_roles:
      my-host-project:
        - roles/compute.networkUser
  terraform-rw: {}
```

Each bucket is represented by one key and a set of optional key/value pairs in the `buckets` top-level YAML map, which exposes most of the variables available in the `gcs` module. Bucket location, storage class and a few other attributes can be defaulted/enforced via project factory level variables.

```yaml
buckets:
  state:
    location: europe-west8
    iam:
      roles/storage.admin:
        - terraform-rw
```

### Automation project and resources

Other than creating automation resources within the project via the `service_accounts` and `buckets` attributes, this module also support management of automation resources created in a separate controlling project. This allows grating broad roles on the project, while still making sure that the automation resources used for Terraform cannot be manipulated from the same identities.

Automation resources are defined via the `automation` attribute in project configurations, which supports:

- a mandatory `project` attribute to define the external controlling project; this attribute does not support interpolation and needs to be explicit
- an optional `service_accounts` list where each element defines a service account in the controlling project
- an optional `bucket` which defines a bucket in the controlling project, and the map of roles/principals in the corresponding value assigned on the created bucket; principals can refer to the created service accounts by key

Service accounts and buckets are prefixed with the project name. Service accounts use the key specified in the YAML file as a suffix, while buckets use a default `tf-state` suffix.

```yaml
# file name: prod-app-example-0
# prefix via factory defaults: foo
# project id: foo-prod-app-example-0
billing_account: 012345-67890A-BCDEF0
parent: folders/12345678
services:
  - compute.googleapis.com
  - stackdriver.googleapis.com
iam:
  roles/owner:
    - rw
  roles/viewer:
    - ro
automation:
  project: foo-prod-iac-core-0
  service_accounts:
    # sa name: foo-prod-app-example-0-rw
    rw:
      description: Read/write automation sa for app example 0.
    # sa name: foo-prod-app-example-0-ro
    ro:
      description: Read-only automation sa for app example 0.
  bucket:
    # bucket name: foo-prod-app-example-0-tf-state
    description: Terraform state bucket for app example 0.
    iam:
      roles/storage.objectCreator:
        - rw
      roles/storage.objectViewer:
        - rw
        - ro
        - group:devops@example.org
```

## Billing budgets

The billing budgets factory integrates the `[`billing-account`](../billing-account/) module functionality, and adds support for easy referencing budgets in project files.

To enable support for billing budgets, set the billing account id, optional notification channels, and the data folder for budgets in the `factories_config.budgets` variable, then create billing budgets using YAML definitions following the format described in the `billing-account` module.

Once budgets are defined, they can be referenced in a project file using their file name:

```yaml
billing_account: 012345-67890A-BCDEF0
labels:
 app: app-1
 team: foo
parent: folders/12345678
services:
  - container.googleapis.com
  - storage.googleapis.com
billing_budgets:
  - test-100
```

A simple billing budget example is show in the [example](#example) below.

## Interpolation in YAML configuration attributes

Interpolation allow referring via short mnemonic names to resources which are either created at runtime, or externally managed.

This feature has two main benefits:

- being able to refer to resource ids which cannot be known before creation, for example project automation service accounts in IAM bindings
- making YAML configuration files more easily readable and portable, by using mnemonic keys which are not specific to an organization or project

One example of both types of contexts is in this project snippet. The automation service account is used in IAM bindings via its `rw` key, while the parent folder is set by referring to its path in the hierarchy factory.

```yaml
parent: teams/team-a
iam:
  "roles/owner":
    - rw
automation:
  project: ta-app0-0
  service_accounts:
    rw:
      description: Read/write automation sa for team a app 0.
  buckets:
    state:
      description: Terraform state bucket for team a app 0.
      iam:
        roles/storage.objectCreator:
          - rw
```

Interpolations leverage contexts from two separate sources: an internal set for resources managed by the project factory (folders, service accounts, etc.), and an external user-defined set passed in via the `factories_config.context` variable.

The following table lists the available context interpolations. External contexts are passed in via the `factories_config.contexts` variable. IAM principals are interpolated in all IAM attributes except `iam_by_principal`. First two columns show for which attribute of which resource context is interpolated. `external contexts` column show in which map passed as `var.factories_config.context` key will be looked up.

- Internally created folders creates keys under `${folder_name_1}[/${folder_name_2}/${folder_name_3}]`
- IAM principals are resolved within context of managed project or use `${project}/${service_account}` to refer service account from other projects managed by the same project factory instance.

| resource            | attribute       | external contexts   | internal contexts                  |
|---------------------|-----------------|---------------------|------------------------------------|
| folder              | parent          | `folder_ids`        | implicit through folder structure  |
| folder              | IAM principals  | `iam_principals`    |                                    |
| folder              | tag bindings    | `tag_values`        |                                    |
| project             | parent          | `folder_ids`        | internally created folders         |
| project             | Shared VPC host | `vpc_host_projects` |                                    |
| project             | Shared VPC IAM  | `iam_principals`    | project service accounts           |
|                     |                 |                     | IaC service accounts               |
|                     |                 |                     | other project service accounts     |
|                     |                 |                     | other project IaC service accounts |
| project             | tag bindings    | `tag_values`        |                                    |
| project             | IAM principals  | `iam_principals`    | project service accounts           |
|                     |                 |                     | IaC service accounts               |
|                     |                 |                     | other project service accounts     |
|                     |                 |                     | other project IaC service accounts |
| bucket              | IAM principals  | `iam_principals`    | project service accounts           |
|                     |                 |                     | IaC service accounts               |
|                     |                 |                     | other project service accounts     |
|                     |                 |                     | other project IaC service accounts |
| service account     | IAM projects    | `vpc_host_projects` |                                    |
| IaC bucket          | IAM principals  | `iam_principals`    | IaC service accounts               |
| IaC service account | IAM principals  | `iam_principals`    |                                    |

## Example

The module invocation using all optional features:

```hcl
module "project-factory" {
  source = "./fabric/modules/project-factory"
  # use a default billing account if none is specified via yaml
  data_defaults = {
    billing_account  = var.billing_account_id
    storage_location = "EU"
  }
  # make sure the environment label and stackdriver service are always added
  data_merges = {
    labels = {
      environment = "test"
    }
    services = [
      "stackdriver.googleapis.com"
    ]
  }
  # always use this contacts and prefix, regardless of what is in the yaml file
  data_overrides = {
    contacts = {
      "admin@example.org" = ["ALL"]
    }
    prefix = "test-pf"
  }
  # location where the yaml files are read from
  factories_config = {
    budgets = {
      billing_account   = var.billing_account_id
      budgets_data_path = "data/budgets"
      notification_channels = {
        billing-default = {
          project_id = "foo-billing-audit"
          type       = "email"
          labels = {
            email_address = "gcp-billing-admins@example.org"
          }
        }
      }
    }
    folders_data_path  = "data/hierarchy"
    projects_data_path = "data/projects"
    context = {
      folder_ids = {
        default = "folders/5678901234"
        teams   = "folders/5678901234"
      }
      iam_principals = {
        gcp-devops = "group:gcp-devops@example.org"
      }
      tag_values = {
        "org-policies/drs-allow-all" = "tagValues/123456"
      }
      vpc_host_projects = {
        dev-spoke-0 = "test-pf-dev-net-spoke-0"
      }
    }
  }
}
# tftest files=0,1,2,3,4,5,6,7,8,9 inventory=example.yaml
```

A simple hierarchy of folders:

```yaml
name: Team A
# implicit parent definition via 'default' key
iam:
  roles/viewer:
    - group:team-a-admins@example.org
    - gcp-devops
# tftest-file id=0 path=data/hierarchy/team-a/_config.yaml schema=folder.schema.json
```

```yaml
name: Team B
# explicit parent definition via key
parent: teams
# tftest-file id=1 path=data/hierarchy/team-b/_config.yaml schema=folder.schema.json
```

```yaml
name: Team C
# explicit parent definition via folder id
parent: folders/5678901234
# tftest-file id=2 path=data/hierarchy/team-c/_config.yaml schema=folder.schema.json
```

```yaml
name: App 0
# tftest-file id=3 path=data/hierarchy/team-a/app-0/_config.yaml schema=folder.schema.json
```

```yaml
name: App 0
tag_bindings:
  drs-allow-all: org-policies/drs-allow-all
# tftest-file id=4 path=data/hierarchy/team-b/app-0/_config.yaml schema=folder.schema.json
```

One project defined within the folder hierarchy:

```yaml
billing_account: 012345-67890A-BCDEF0
services:
  - container.googleapis.com
  - storage.googleapis.com
# tftest-file id=5 path=data/hierarchy/teams-iac-0.yaml schema=project.schema.json
```

More traditional project definitions via the project factory data:

```yaml
billing_account: 012345-67890A-BCDEF0
labels:
 app: app-0
 team: team-a
parent: team-a/app-0
service_encryption_key_ids:
 storage.googleapis.com:
  - projects/kms-central-prj/locations/europe-west3/keyRings/my-keyring/cryptoKeys/europe3-gce
services:
  - container.googleapis.com
  - storage.googleapis.com
service_accounts:
  app-0-be:
    display_name: "Backend instances."
    iam_project_roles:
      dev-spoke-0:
        - roles/compute.networkUser
    iam_self_roles:
      - roles/logging.logWriter
      - roles/monitoring.metricWriter
  app-0-fe:
    display_name: "Frontend instances."
    iam_project_roles:
      dev-spoke-0:
        - roles/compute.networkUser
    iam_self_roles:
      - roles/logging.logWriter
      - roles/monitoring.metricWriter
shared_vpc_service_config:
  host_project: dev-spoke-0
  network_users:
    - gcp-devops
  service_agent_iam:
    "roles/container.hostServiceAgentUser":
      - container-engine
    "roles/compute.networkUser":
      - container-engine
billing_budgets:
  - test-100
tags:
  my-tag-key-1:
    values:
      my-value-1:
        description: My value 1
      my-value-2:
        description: My value 3
        iam:
          roles/resourcemanager.tagUser:
            - user:user@example.com
# tftest-file id=6 path=data/projects/dev-ta-app0-be.yaml schema=project.schema.json
```

This project defines a controlling project via the `automation` attributes:

```yaml
parent: team-b/app-0
services:
- run.googleapis.com
- storage.googleapis.com
iam:
  "roles/owner":
    - automation/rw
  "roles/viewer":
    - automation/ro
shared_vpc_host_config:
  enabled: true
automation:
  project: test-pf-teams-iac-0
  service_accounts:
    rw:
      description: Team B app 0 read/write automation sa.
    ro:
      description: Team B app 0 read-only automation sa.
  bucket:
    description: Team B app 0 Terraform state bucket.
    iam:
      roles/storage.objectCreator:
        - automation/rw
      roles/storage.objectViewer:
        - gcp-devops
        - group:team-b-admins@example.org
        - automation/rw
        - automation/ro

# tftest-file id=7 path=data/projects/dev-tb-app0-0.yaml schema=project.schema.json
```

A billing budget:

```yaml
# billing budget test-100
display_name: 100 dollars in current spend
amount:
  units: 100
filter:
  period:
    calendar: MONTH
  resource_ancestors:
  - folders/1234567890
threshold_rules:
- percent: 0.5
- percent: 0.75
update_rules:
  default:
    disable_default_iam_recipients: true
    monitoring_notification_channels:
    - billing-default
# tftest-file id=8 path=data/budgets/test-100.yaml schema=budget.schema.json
```

Granting permissions to service accounts defined in other project through interpolation:

```yaml
billing_account: 012345-67890A-BCDEF0
labels:
 app: app-0
 team: team-b
parent: team-b/app-0
services:
  - container.googleapis.com
  - storage.googleapis.com
iam:
  "roles/run.admin":
    - dev-ta-app0-be/app-0-be # interpolate to app-0-be service account in project defined in file dev-ta-app0-be
  "roles/run.developer":
    - app-0-be # interpolate to app-0-be service account within the same project
service_accounts:
  app-0-be:
    display_name: "Backend instances."
    iam_self_roles:
      - roles/logging.logWriter
      - roles/monitoring.metricWriter
# tftest-file id=9 path=data/projects/dev-tb-app0-1.yaml schema=project.schema.json
```

<!-- TFDOC OPTS files:1 -->
<!-- BEGIN TFDOC -->
## Files

| name | description | modules |
|---|---|---|
| [automation.tf](./automation.tf) | Automation projects locals and resources. | <code>gcs</code> · <code>iam-service-account</code> |
| [factory-budgets.tf](./factory-budgets.tf) | Billing budget factory locals. |  |
| [factory-folders.tf](./factory-folders.tf) | Folder hierarchy factory locals. |  |
| [factory-projects-object.tf](./factory-projects-object.tf) | None |  |
| [factory-projects.tf](./factory-projects.tf) | Projects factory locals. |  |
| [folders.tf](./folders.tf) | Folder hierarchy factory resources. | <code>folder</code> |
| [main.tf](./main.tf) | Projects and billing budgets factory resources. | <code>billing-account</code> · <code>gcs</code> · <code>iam-service-account</code> · <code>project</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  |
| [variables.tf](./variables.tf) | Module variables. |  |

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [factories_config](variables.tf#L121) | Path to folder with YAML resource description data files. | <code title="object&#40;&#123;&#10;  budgets &#61; optional&#40;object&#40;&#123;&#10;    billing_account   &#61; string&#10;    budgets_data_path &#61; string&#10;    notification_channels &#61; optional&#40;map&#40;any&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;&#41;&#10;  context &#61; optional&#40;object&#40;&#123;&#10;    folder_ids            &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;    iam_principals        &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;    perimeters            &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;    tag_values            &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;    vpc_host_projects     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;    notification_channels &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  folders_data_path  &#61; optional&#40;string&#41;&#10;  projects_data_path &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [data_defaults](variables.tf#L17) | Optional default values used when corresponding project data from files are missing. | <code title="object&#40;&#123;&#10;  billing_account &#61; optional&#40;string&#41;&#10;  contacts        &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  factories_config &#61; optional&#40;object&#40;&#123;&#10;    custom_roles  &#61; optional&#40;string&#41;&#10;    observability &#61; optional&#40;string&#41;&#10;    org_policies  &#61; optional&#40;string&#41;&#10;    quotas        &#61; optional&#40;string&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  labels                     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  metric_scopes              &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  parent                     &#61; optional&#40;string&#41;&#10;  prefix                     &#61; optional&#40;string&#41;&#10;  service_encryption_key_ids &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  services                   &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  shared_vpc_service_config &#61; optional&#40;object&#40;&#123;&#10;    host_project             &#61; string&#10;    network_users            &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    service_agent_iam        &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;    service_agent_subnet_iam &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;    service_iam_grants       &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    network_subnet_users     &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;, &#123; host_project &#61; null &#125;&#41;&#10;  storage_location &#61; optional&#40;string&#41;&#10;  tag_bindings     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  service_accounts &#61; optional&#40;map&#40;object&#40;&#123;&#10;    display_name   &#61; optional&#40;string, &#34;Terraform-managed.&#34;&#41;&#10;    iam_self_roles &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  vpc_sc &#61; optional&#40;object&#40;&#123;&#10;    perimeter_name    &#61; string&#10;    perimeter_bridges &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    is_dry_run        &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;&#41;&#10;  logging_data_access &#61; optional&#40;map&#40;object&#40;&#123;&#10;    ADMIN_READ &#61; optional&#40;object&#40;&#123; exempted_members &#61; optional&#40;list&#40;string&#41;&#41; &#125;&#41;&#41;,&#10;    DATA_READ  &#61; optional&#40;object&#40;&#123; exempted_members &#61; optional&#40;list&#40;string&#41;&#41; &#125;&#41;&#41;,&#10;    DATA_WRITE &#61; optional&#40;object&#40;&#123; exempted_members &#61; optional&#40;list&#40;string&#41;&#41; &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [data_merges](variables.tf#L64) | Optional values that will be merged with corresponding data from files. Combines with `data_defaults`, file data, and `data_overrides`. | <code title="object&#40;&#123;&#10;  contacts                   &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  labels                     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  metric_scopes              &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  service_encryption_key_ids &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  services                   &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  tag_bindings               &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  service_accounts &#61; optional&#40;map&#40;object&#40;&#123;&#10;    display_name   &#61; optional&#40;string, &#34;Terraform-managed.&#34;&#41;&#10;    iam_self_roles &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [data_overrides](variables.tf#L83) | Optional values that override corresponding data from files. Takes precedence over file data and `data_defaults`. | <code title="object&#40;&#123;&#10;  billing_account &#61; optional&#40;string&#41;&#10;  contacts        &#61; optional&#40;map&#40;list&#40;string&#41;&#41;&#41;&#10;  factories_config &#61; optional&#40;object&#40;&#123;&#10;    custom_roles  &#61; optional&#40;string&#41;&#10;    observability &#61; optional&#40;string&#41;&#10;    org_policies  &#61; optional&#40;string&#41;&#10;    quotas        &#61; optional&#40;string&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  parent                     &#61; optional&#40;string&#41;&#10;  prefix                     &#61; optional&#40;string&#41;&#10;  service_encryption_key_ids &#61; optional&#40;map&#40;list&#40;string&#41;&#41;&#41;&#10;  storage_location           &#61; optional&#40;string&#41;&#10;  tag_bindings               &#61; optional&#40;map&#40;string&#41;&#41;&#10;  services                   &#61; optional&#40;list&#40;string&#41;&#41;&#10;  service_accounts &#61; optional&#40;map&#40;object&#40;&#123;&#10;    display_name   &#61; optional&#40;string, &#34;Terraform-managed.&#34;&#41;&#10;    iam_self_roles &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;&#41;&#10;  vpc_sc &#61; optional&#40;object&#40;&#123;&#10;    perimeter_name    &#61; string&#10;    perimeter_bridges &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    is_dry_run        &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;&#41;&#10;  logging_data_access &#61; optional&#40;map&#40;object&#40;&#123;&#10;    ADMIN_READ &#61; optional&#40;object&#40;&#123; exempted_members &#61; optional&#40;list&#40;string&#41;&#41; &#125;&#41;&#41;,&#10;    DATA_READ  &#61; optional&#40;object&#40;&#123; exempted_members &#61; optional&#40;list&#40;string&#41;&#41; &#125;&#41;&#41;,&#10;    DATA_WRITE &#61; optional&#40;object&#40;&#123; exempted_members &#61; optional&#40;list&#40;string&#41;&#41; &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [buckets](outputs.tf#L17) | Bucket names. |  |
| [folders](outputs.tf#L24) | Folder ids. |  |
| [projects](outputs.tf#L29) | Created projects. |  |
| [service_accounts](outputs.tf#L52) | Service account emails. |  |
<!-- END TFDOC -->
## Tests

These tests validate fixes to the project factory.

```hcl
module "project-factory" {
  source = "./fabric/modules/project-factory"
  data_defaults = {
    billing_account = "012345-67890A-ABCDEF"
  }
  data_merges = {
    labels = {
      owner = "foo"
    }
    services = [
      "compute.googleapis.com"
    ]
  }
  data_overrides = {
    prefix = "foo"
  }
  factories_config = {
    projects_data_path = "data/projects"
  }
}
# tftest modules=4 resources=22 files=test-0,test-1,test-2
```

```yaml
parent: folders/1234567890
services:
  - iam.googleapis.com
  - contactcenteraiplatform.googleapis.com
  - container.googleapis.com
# tftest-file id=test-0 path=data/projects/test-0.yaml
```

```yaml
parent: folders/1234567890
services:
  - iam.googleapis.com
  - contactcenteraiplatform.googleapis.com
# tftest-file id=test-1 path=data/projects/test-1.yaml
```

```yaml
parent: folders/1234567890
services:
  - iam.googleapis.com
  - storage.googleapis.com
# tftest-file id=test-2 path=data/projects/test-2.yaml
```
