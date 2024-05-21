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

- forlder admin permissions for the hierarchy
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
- [Example](#example)
- [Files](#files)
- [Variables](#variables)
- [Outputs](#outputs)
- [Tests](#tests)
<!-- END TOC -->

## Folder hierarchy

The hierarchy supports up to three levels of folders, which are defined via filesystem directories each including a `_config.yaml` files detailing their attributes.

The hierarchy factory is configured via the `factories_config.hierarchy` variable via one mandatory and one optional argument:

- `factories_config.hierarchy.folders_data_path` is required to enable the hierarchy factory, and must be set to the path containing the YAML definitions
- `factories_config.hierarchy.parent_ids` is an optional map where keys are arbitrary and values are set to resource node ids

Top-level folders in the filesystem hierarchy have no explicit parent, so their parent ids need to be provided in the YAML by either referencing the full id (e.g. `folders/12345678`) or by referencing a key in the `parent_ids` attribute described above. As a shortcut, a `default` key can be defined whose value is used for any top-level folder which does not directly provide a parent id.

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

Each service account is represented by one key and a set of optional key/value pairs in the `service_accounts` top-level YAML map, which expose most of the variables available in the `iam-service-account` module:

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
      "admin@example.com" = ["ALL"]
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
            email_address = "gcp-billing-admins@example.com"
          }
        }
      }
    }
    hierarchy = {
      folders_data_path = "data/hierarchy"
      parent_ids = {
        default = "folders/12345678"
      }
    }
    projects_data_path = "data/projects"
  }
}
# tftest modules=16 resources=55 files=prj-app-1,prj-app-2,prj-app-3,budget-test-100,h-0-0,h-1-0,h-0-1,h-1-1,h-1-1-p0 inventory=example.yaml
```

A simple hierarchy of folders:

```yaml
name: Foo (level 1)
iam:
  roles/viewer:
    - group:a@example.com
# tftest-file id=h-0-0 path=data/hierarchy/foo/_config.yaml
```

```yaml
name: Bar (level 1)
parent: folders/4567890
# tftest-file id=h-1-0 path=data/hierarchy/bar/_config.yaml
```

```yaml
name: Foo Baz (level 2)
# tftest-file id=h-0-1 path=data/hierarchy/foo/baz/_config.yaml
```

```yaml
name: Bar Baz (level 2)
# tftest-file id=h-1-1 path=data/hierarchy/bar/baz/_config.yaml
```

One project defined within the folder hierarchy:

```yaml
billing_account: 012345-67890A-BCDEF0
services:
  - container.googleapis.com
  - storage.googleapis.com
# tftest-file id=h-1-1-p0 path=data/hierarchy/bar/baz/bar-baz-iac-0.yaml
```

More traditional project definitions via the project factory data:

```yaml
# project app-1
billing_account: 012345-67890A-BCDEF0
labels:
 app: app-1
 team: foo
parent: folders/12345678
service_encryption_key_ids:
 compute:
 - projects/kms-central-prj/locations/europe-west3/keyRings/my-keyring/cryptoKeys/europe3-gce
services:
  - container.googleapis.com
  - storage.googleapis.com
service_accounts:
  app-1-be:
    iam_self_roles:
    - roles/logging.logWriter
    - roles/monitoring.metricWriter
    iam_project_roles:
      my-host-project:
        - roles/compute.networkUser
  app-1-fe:
    display_name: "Test app 1 frontend."
    iam_project_roles:
      my-host-project:
        - roles/compute.networkUser
billing_budgets:
  - test-100
# tftest-file id=prj-app-1 path=data/projects/prj-app-1.yaml
```

```yaml
# project app-2
labels:
  app: app-2
  team: foo
parent: folders/12345678
org_policies:
  "compute.restrictSharedVpcSubnetworks":
    rules:
    - allow:
        values:
        - projects/foo-host/regions/europe-west1/subnetworks/prod-default-ew1
service_accounts:
  app-2-be: {}
services:
- compute.googleapis.com
- container.googleapis.com
- run.googleapis.com
- storage.googleapis.com
shared_vpc_service_config:
  host_project: foo-host
  service_identity_iam:
    "roles/vpcaccess.user":
    - cloudrun
    "roles/container.hostServiceAgentUser":
    - container-engine
  service_identity_subnet_iam:
    europe-west1/prod-default-ew1:
    - cloudservices
    - container-engine
  network_subnet_users:
    europe-west1/prod-default-ew1:
    - group:team-1@example.com

# tftest-file id=prj-app-2 path=data/projects/prj-app-2.yaml
```

This project uses a reference to a hierarchy folder, and defines a controlling project via the `automation` attributes:

```yaml
parent: bar/baz
services:
- run.googleapis.com
- storage.googleapis.com
iam:
  "roles/owner":
    - rw
  "roles/viewer":
    - ro
automation:
  project: bar-baz-iac-0
  service_accounts:
    rw:
      description: Read/write automation sa for app example 0.
    ro:
      description: Read-only automation sa for app example 0.
  buckets:
    state:
      description: Terraform state bucket for app example 0.
      iam:
        roles/storage.objectCreator:
          - rw
        roles/storage.objectViewer:
          - rw
          - ro
          - group:devops@example.org


# tftest-file id=prj-app-3 path=data/projects/prj-app-3.yaml
```

And a billing budget:

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
# tftest-file id=budget-test-100 path=data/budgets/test-100.yaml
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
| [factories_config](variables.tf#L96) | Path to folder with YAML resource description data files. | <code title="object&#40;&#123;&#10;  hierarchy &#61; optional&#40;object&#40;&#123;&#10;    folders_data_path &#61; string&#10;    parent_ids        &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;&#41;&#10;  projects_data_path &#61; optional&#40;string&#41;&#10;  budgets &#61; optional&#40;object&#40;&#123;&#10;    billing_account   &#61; string&#10;    budgets_data_path &#61; string&#10;    notification_channels &#61; optional&#40;map&#40;any&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [data_defaults](variables.tf#L17) | Optional default values used when corresponding project data from files are missing. | <code title="object&#40;&#123;&#10;  billing_account            &#61; optional&#40;string&#41;&#10;  contacts                   &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  labels                     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  metric_scopes              &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  parent                     &#61; optional&#40;string&#41;&#10;  prefix                     &#61; optional&#40;string&#41;&#10;  service_encryption_key_ids &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  services                   &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  shared_vpc_service_config &#61; optional&#40;object&#40;&#123;&#10;    host_project                &#61; string&#10;    network_users               &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    service_identity_iam        &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;    service_identity_subnet_iam &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;    service_iam_grants          &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    network_subnet_users        &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;, &#123; host_project &#61; null &#125;&#41;&#10;  tag_bindings &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  service_accounts &#61; optional&#40;map&#40;object&#40;&#123;&#10;    display_name   &#61; optional&#40;string, &#34;Terraform-managed.&#34;&#41;&#10;    iam_self_roles &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  vpc_sc &#61; optional&#40;object&#40;&#123;&#10;    perimeter_name    &#61; string&#10;    perimeter_bridges &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    is_dry_run        &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
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
# tftest modules=4 resources=14 files=test-0,test-1,test-2
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
