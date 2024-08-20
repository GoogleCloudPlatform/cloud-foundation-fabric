# Project and Folder Factory

This module implements end-to-end creation processes for a folder hierarchy,   projects and billing budgets via YAML data configurations.

It supports

- filesystem-driven folder hierarchy exposing the full configuration options available in the [folder module](../folder/)
- multiple project creation and management exposing the full configuration options available in the [project module](../project/), including KMS key grants and VPC-SC perimeter membership
- optional per-project [service account management](#service-accounts) including basic IAM grants
- optional [billing budgets](#billing-budgets) factory and budget/project associations
- cross-referencing of hierarchy folders in projects
- optional per-project IaC configuration (TODO)

The factory is implemented as a thin data translation layer for the underlying modules, so that no "magic" or hidden side effects are implemented in code, and debugging or integration of new features are simple.

The code is meant to be executed by a high level service accounts with powerful permissions:

- folder admin permissions for the hierarchy
- project creation on the nodes (folder or org) where projects will be defined
- Shared VPC connection if service project attachment is desired
- billing cost manager permissions to manage budgets and monitoring permissions if notifications should also be managed here

<!-- BEGIN TOC -->
- [Folder hierarchy](#folder-hierarchy)
- [Projects](#projects)
  - [Factory-wide project defaults, merges, optionals](#factory-wide-project-defaults-merges-optionals)
  - [Service accounts](#service-accounts)
  - [Automation project and resources](#automation-project-and-resources)
- [Billing budgets](#billing-budgets)
- [Substitutions in YAML configurations attributes](#substitutions-in-yaml-configurations-attributes)
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

### Service accounts

Service accounts can be managed as part of each project's YAML configuration. This allows creation of default service accounts used for GCE instances, in firewall rules, or for application-level credentials without resorting to a separate Terraform configuration.

Each service account is represented by one key and a set of optional key/value pairs in the `service_accounts` top-level YAML map, which exposes most of the variables available in the `iam-service-account` module:

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
```

Both the `display_name` and `iam_self_roles` attributes are optional.

### Automation project and resources

Project configurations also support defining service accounts and storage buckets to support automation, created in a separate controlling project so as to be outside of the sphere of control of the managed project.

Automation resources are defined via the `automation` attribute in project configurations, which supports:

- a mandatory `project` attribute to define the external controlling project
- an optional `service_accounts` list where each element will define a service account in the controlling project
- an optional `buckets` map where each key will define a bucket in the controlling project, and the map of roles/principals in the corresponding value assigned on the created bucket; principals can refer to the created service accounts by key

Service accounts and buckets will be prefixed with the project name, and use the key specified in the YAML file as a suffix.

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
  buckets:
    # bucket name: foo-prod-app-example-0-state
    state:
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

## Substitutions in YAML configurations attributes

Substitutions allow referring via short mnemonic names to resources which are either created at runtime, or externally manages.

This feature has two main benefits:

- being able to refer to resource ids which cannot be known before creation, for example project automation service accounts in IAM bindings
- making YAML configuration files more easily readable and portable, by using mnemonic keys which are not specific to an organization or project

One example of both types of substitutions is in this project snippet. The automation service account is used in IAM bindings via its `rw` key, while the parent folder is set by referring to its path in the hierarchy factory.

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

Substitutions come from two separate context sources: an internal set for resources managed by the project factory (folders, service accounts, etc.), and an external user-defined set passed in via the `factories_config.context` variable.

Internal substitutions are:

- hierarchy folders, used to set project parents via the filesystem path of folders (e.g. `teams/team-a`)
- automation service accounts, used in project IAM bindings via their keys; this does not work in folder IAM bindings

External substitution are:

- the map of folder ids in `factories_config.context.folder_ids`, used to set top-level folder parents; the `default` key if present is used when no explicit parent has been set in the YAML file
- the map of IAM principals in `factories_config.context.iam_principals`, used in IAM bindings for folders and projects; the exception is the `iam_by_principals` attribute which uses no interpolation to prevent dynamic cycles
- the map of tag value ids in `factories_config.context.tag_values` used in tag bindings for folders and projects
- the map of Shared VPC host project ids in `factories_config.context.vpc_host_projects` used in service project configurations for projects

External substitution maps are optional, and there's no harm in not defining them if not used.

Some caveats on substitutions:

- project-own service accounts are not part of substitutions to prevent cycles, you can use the `iam_project_roles` and `iam_self_roles` attributes for additive IAM on projects
- project shared vpc configurations and project-own service accounts only support external substitutions to prevent cycles
- projects for automation service accounts and buckets do not support substitutions to prevent cycles
- no substitutions are implemented (yet) for budgets

## Example

The module invocation using all optional features:

```hcl
module "project-factory" {
  source = "./fabric/modules/project-factory"
  # use a default billing account if none is specified via yaml
  data_defaults = {
    billing_account = var.billing_account_id
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
  # always use this contaxt and prefix, regardless of what is in the yaml file
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
# tftest modules=15 resources=56 files=0,1,2,3,4,5,6,7,8 inventory=example.yaml
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
    - rw
  "roles/viewer":
    - ro
shared_vpc_host_config:
  enabled: true
automation:
  project: test-pf-teams-iac-0
  service_accounts:
    rw:
      description: Team B app 0 read/write automation sa.
    ro:
      description: Team B app 0 read-only automation sa.
  buckets:
    state:
      description: Team B app 0 Terraform state bucket.
      iam:
        roles/storage.objectCreator:
          - rw
        roles/storage.objectViewer:
          - gcp-devops
          - group:team-b-admins@example.org
          - rw
          - ro

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

<!-- TFDOC OPTS files:1 -->
<!-- BEGIN TFDOC -->
## Files

| name | description | modules |
|---|---|---|
| [automation.tf](./automation.tf) | Automation projects locals and resources. | <code>gcs</code> · <code>iam-service-account</code> |
| [factory-budgets.tf](./factory-budgets.tf) | Billing budget factory locals. |  |
| [factory-folders.tf](./factory-folders.tf) | Folder hierarchy factory locals. |  |
| [factory-projects.tf](./factory-projects.tf) | Projects factory locals. |  |
| [folders.tf](./folders.tf) | Folder hierarchy factory resources. | <code>folder</code> |
| [main.tf](./main.tf) | Projects and billing budgets factory resources. | <code>billing-account</code> · <code>iam-service-account</code> · <code>project</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  |
| [variables.tf](./variables.tf) | Module variables. |  |

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [factories_config](variables.tf#L96) | Path to folder with YAML resource description data files. | <code title="object&#40;&#123;&#10;  folders_data_path  &#61; optional&#40;string&#41;&#10;  projects_data_path &#61; optional&#40;string&#41;&#10;  budgets &#61; optional&#40;object&#40;&#123;&#10;    billing_account   &#61; string&#10;    budgets_data_path &#61; string&#10;    notification_channels &#61; optional&#40;map&#40;any&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;&#41;&#10;  context &#61; optional&#40;object&#40;&#123;&#10;    folder_ids        &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;    iam_principals    &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;    tag_values        &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;    vpc_host_projects &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [data_defaults](variables.tf#L17) | Optional default values used when corresponding project data from files are missing. | <code title="object&#40;&#123;&#10;  billing_account            &#61; optional&#40;string&#41;&#10;  contacts                   &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  labels                     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  metric_scopes              &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  parent                     &#61; optional&#40;string&#41;&#10;  prefix                     &#61; optional&#40;string&#41;&#10;  service_encryption_key_ids &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  services                   &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  shared_vpc_service_config &#61; optional&#40;object&#40;&#123;&#10;    host_project             &#61; string&#10;    network_users            &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    service_agent_iam        &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;    service_agent_subnet_iam &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;    service_iam_grants       &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    network_subnet_users     &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;, &#123; host_project &#61; null &#125;&#41;&#10;  tag_bindings &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  service_accounts &#61; optional&#40;map&#40;object&#40;&#123;&#10;    display_name   &#61; optional&#40;string, &#34;Terraform-managed.&#34;&#41;&#10;    iam_self_roles &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  vpc_sc &#61; optional&#40;object&#40;&#123;&#10;    perimeter_name    &#61; string&#10;    perimeter_bridges &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    is_dry_run        &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [data_merges](variables.tf#L52) | Optional values that will be merged with corresponding data from files. Combines with `data_defaults`, file data, and `data_overrides`. | <code title="object&#40;&#123;&#10;  contacts                   &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  labels                     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  metric_scopes              &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  service_encryption_key_ids &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  services                   &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  tag_bindings               &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  service_accounts &#61; optional&#40;map&#40;object&#40;&#123;&#10;    display_name   &#61; optional&#40;string, &#34;Terraform-managed.&#34;&#41;&#10;    iam_self_roles &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [data_overrides](variables.tf#L71) | Optional values that override corresponding data from files. Takes precedence over file data and `data_defaults`. | <code title="object&#40;&#123;&#10;  billing_account            &#61; optional&#40;string&#41;&#10;  contacts                   &#61; optional&#40;map&#40;list&#40;string&#41;&#41;&#41;&#10;  parent                     &#61; optional&#40;string&#41;&#10;  prefix                     &#61; optional&#40;string&#41;&#10;  service_encryption_key_ids &#61; optional&#40;map&#40;list&#40;string&#41;&#41;&#41;&#10;  tag_bindings               &#61; optional&#40;map&#40;string&#41;&#41;&#10;  services                   &#61; optional&#40;list&#40;string&#41;&#41;&#10;  service_accounts &#61; optional&#40;map&#40;object&#40;&#123;&#10;    display_name   &#61; optional&#40;string, &#34;Terraform-managed.&#34;&#41;&#10;    iam_self_roles &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;&#41;&#10;  vpc_sc &#61; optional&#40;object&#40;&#123;&#10;    perimeter_name    &#61; string&#10;    perimeter_bridges &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    is_dry_run        &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [folders](outputs.tf#L17) | Folder ids. |  |
| [projects](outputs.tf#L22) | Project module outputs. |  |
| [service_accounts](outputs.tf#L27) | Service account emails. |  |
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
