# Project and Folder Factory

This module implements end-to-end creation processes for a folder hierarchy,   projects and billing budgets via YAML data configurations.

It supports

- filesystem-driven folder hierarchy exposing the full configuration options available in the [folder module](../folder/)
- multiple project creation and management exposing the full configuration options available in the [project module](../project/), including KMS key grants and VPC-SC perimeter membership
- optional per-project [service accounts and buckets management](#service-accounts-and-buckets) including basic IAM grants
- optional [billing budgets](#billing-budgets) factory and budget/project associations
- cross-referencing of hierarchy folders in projects
- optional per-project IaC configuration
- global defaults or overrides for most project configurations
- extensive support of [context-based interpolation](#context-based-interpolation)

The factory is implemented as a thin data translation layer over the underlying modules, so that no "magic" or hidden side effects are implemented in code, and debugging or integration of new features are simple.

The code is meant to be executed by a high level service account with powerful permissions:

- folder admin permissions for the hierarchy
- project creation on the nodes (folder or org) where projects will be defined
- Shared VPC connection if service project attachment is desired
- VPC Service Controls perimeter management if project inclusion is desired
- billing cost manager permissions to manage budgets and monitoring permissions if notifications should also be managed here

## Contents

<!-- BEGIN TOC -->
- [Folder hierarchy](#folder-hierarchy)
- [Projects](#projects)
  - [Factory-wide project defaults, merges, optionals](#factory-wide-project-defaults-merges-optionals)
  - [Project templates](#project-templates)
  - [Service accounts and buckets](#service-accounts-and-buckets)
  - [Automation resources](#automation-resources)
    - [Prefix handling](#prefix-handling)
    - [Complete automation example](#complete-automation-example)
- [Billing budgets](#billing-budgets)
- [Context-based interpolation](#context-based-interpolation)
  - [Folder context ids](#folder-context-ids)
  - [Project context ids](#project-context-ids)
  - [Service account context ids](#service-account-context-ids)
  - [Other context ids](#other-context-ids)
- [Example](#example)
- [Files](#files)
- [Variables](#variables)
- [Outputs](#outputs)
- [Tests](#tests)
<!-- END TOC -->

## Folder hierarchy

The hierarchy supports up to three levels of folders, which are defined via filesystem directories each including a `.config.yaml` files detailing their attributes.

The filesystem tree containing folder definitions is configured via the `factories_config.folders` variable, which sets the the path containing the YAML definitions for folders. It's also possible to configure the hierarchy via the `folders` variable, which is internally merged in with the factory definitions.

Parent ids for top-level folders can either be set explicitly (e.g. `folders/12345678`), or via [context interpolation](#context-based-interpolation) by referring to keys in the `context.folder_ids` variable. The special `default` key in the substitutions folder variable is used if present and no folder id/key has been specified in the YAML.

Filesystem directories can also contain project definitions in the same YAML format described below. This approach must be used with caution and is best adopted for stable scenarios, as problems in the filesystem hierarchy definitions might result in the project files not being read and the resources being deleted by Terraform.

Refer to the [example](#example) below for actual examples of the YAML definitions.

## Projects

The project factory is configured in three ia the `factories_config.projects` variable, and project files are also additionally read from the folder tree described in the previous section. It's best to limit project definition via the hierarchy tree to a minimum to avoid cross dependencies between folders and projects, which could complicate their lifecycle.

Projects can also be configured via the `projects` variable, which is internally merged in with the factory definitions.

The YAML format mirrors the project module, refer to the [example](#example) below for actual examples of the YAML definitions.

### Factory-wide project defaults, merges, optionals

In addition to the YAML-based project configurations, the factory accepts three additional sets of inputs via Terraform variables:

- the `data_defaults` variable allows defining defaults for specific project attributes, which are only used if the attributes are not passed in via YAML
- the `data_overrides` variable works similarly to defaults, but the values specified here take precedence over those in YAML files
- the `data_merges` variable allows specifying additional values for map or set based variables, which are merged with the data coming from YAML

Some examples on where to use each of the three sets are [provided below](#example).

### Project templates

Project templates are project definitions that can be "inherited" and extended in YAML-based project configurations. Templates are YAML files which use the same schema as a project, but which don't directly trigger project creation by themselves.

When referenced in a project configuration file, a template attributes are used as the initial project definition, over which the project's own attributes are merged. The merge is shallow, so any attribute which is defined in the project configuration will take precedence and completely override the template's own definition.

For example, declaring `iam` or `org_policies` in the template and then doing the same in the project file will result in those two attributes in the template being ignored.

The set of available templates is defined via a dedicated path in the `factories_config` file, and then a template can be referenced from a project definition via the `project_template` YAML attribute.

### Service accounts and buckets

Service accounts and GCS buckets can be managed as part of each project's YAML configuration. This allows creation of default service accounts used for GCE instances, in firewall rules, or for application-level credentials without resorting to a separate Terraform configuration.

Each service account is represented by one key and a set of optional key/value pairs in the `service_accounts` top-level YAML map, which exposes most of the variables available in the `iam-service-account` module. Most of the service accounts attributes are optional.

```yaml
service_accounts:
  be-0: {}
  fe-1:
    display_name: GCE frontend service account.
    iam_self_roles:
      - roles/storage.objectViewer
    iam_project_roles:
      $project_ids:my-host-project:
        - roles/compute.networkUser
    iam_sa_roles:
      $iam_principals:service_accounts/my-project/be-0:
        - roles/iam.serviceAccountUser
  terraform-rw: {}
```

Each bucket is represented by one key and a set of optional key/value pairs in the `buckets` top-level YAML map, which exposes most of the variables available in the `gcs` module. Bucket location, storage class and a few other attributes can be defaulted/enforced via project factory level variables.

```yaml
buckets:
  state:
    location: europe-west8
    iam:
      roles/storage.admin:
        - $iam_principals:service_accounts/my-project/terraform-rw
```

### Automation resources

Other than creating automation resources within the project via the `service_accounts` and `buckets` attributes, this module also supports management of automation resources created in a separate controlling project.

This allows granting broad roles on the project while ensuring that the automation resources used for Terraform are under a separate span of control. It also allows grouping together in a single file all resources specific to the same task, making template distribution easier.

Automation resources are defined via the `automation` attribute in project configurations, which supports:

- a mandatory `project` attribute to define the external controlling project; this attribute does not support interpolation and needs to be explicit
- an optional `service_accounts` list where each element defines a service account in the controlling project
- an optional `bucket` which defines a bucket and/org managed folders in the controlling project; bucket names cannot use interpolation so where bucket creation is not needed, they need to be explicit

#### Prefix handling

To easily distinguish automation resources in the controlling project, service account and bucket names use a prefix that embeds the "local" project name to the default prefix. Due to the difference in maximum length and name uniqueness, service accounts and buckets treat the prefix differently.

For service accounts the global prefix is ignored, and the "local" project name is used as a prefix. For example, a project defined in a `prod-app-example-0.yaml` file where the prefix is `foo` will have the `rw` automation service account resulting in the `prod-app-example-0-rw` name.

For GCS buckets the global prefix is kept to ensure name uniqueness, and the "local" project name is appended. For example, a project defined in a `prod-app-example-0.yaml` file where the prefix is `foo` will have the `tf-state` automation bucket resulting in the `foo-prod-app-example-0-tf-state` name.

This behaviour changes when bucket creation is set to `false`, which is the pattern used when GCS managed folders are used for each project automation. In these cases the prefix for the bucket is not suffixed with the local project name, to make it possible to refer to the pre-existing bucket.

The difference in the two behaviours is shown in the snippets below.

```yaml
# file/project name: prod-example-app-0
# prefix via factory defaults: foo

automation:
  project: $project_ids:iac-core-0
  bucket:
    name: tf-state

# bucket is created, name is foo-prod-example-app-0-tf-state
```

```yaml
# file/project name: prod-example-app-0
# prefix via factory defaults: foo
# pre-existing bucket: foo-prod-iac-core-0-shared-tf-state

automation:
  project: $project_ids:iac-core-0
  bucket:
    name: prod-iac-core-0-shared-tf-state
    create: false
    managed_folders:
      prod-example-app-0: {}

# managed folder prod-example-app-0 is created
# in bucket foo-prod-iac-core-0-shared-tf-state
```

#### Complete automation example

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
    - $iam_principals:service_accounts/iac-core-0/rw
  roles/viewer:
    - $iam_principals:service_accounts/iac-core-0/ro
automation:
  project: $project_ids:iac-core-0
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
        - $iam_principals:service_accounts/iac-core-0/rw
      roles/storage.objectViewer:
        - $iam_principals:service_accounts/iac-core-0/rw
        - $iam_principals:service_accounts/iac-core-0/ro
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

## Context-based interpolation

Interpolation allow referring to resources which are either created at runtime, or externally managed via short aliases.

This feature has two main benefits:

- being able to refer to resource ids which cannot be known before creation, for example project automation service accounts in IAM bindings
- making YAML configuration files more easily readable and portable, by using mnemonic keys which are not specific to an organization or project

One example of both types of contexts is in this project snippet. The automation service account is used in IAM bindings via its key, while the parent folder is set by referring to its path in the hierarchy factory.

```yaml
# file name: my-project
parent: $folder_ids:teams/team-a
iam:
  "roles/owner":
    - $iam_principals:service_accounts/my-project/rw
automation:
  project: $project_ids:ta-app0-0
  service_accounts:
    rw:
      description: Read/write automation sa for team a app 0.
  buckets:
    state:
      description: Terraform state bucket for team a app 0.
      iam:
        roles/storage.objectCreator:
          - $iam_principals:service_accounts/my-project/rw
```

Interpolations leverage contexts from two separate sources: resources managed by the project factory (folders, service accounts, etc.), and user-defined resource ids passed in via the `context` variable.

Context replacements use the `$` prefix and are accessible via namespaces that match the attributes in the context variable.

Context variables are accessed by keys that match the YAML file name for resources declared in individual files (projects, folders, custom roles, etc.), or the key in the YAML map where the resource is declared for other resources (service accounts, buckets, etc.).

Assuming keys of the form `my_folder`, `my_project`, `my_sa`, etc. this is an example of referencing the actual IDs via interpolation in YAML files.

- `$custom_roles:my_role`
- `$folder_ids:my_folder`
- `$iam_principals:my_principal`
- `$iam_principals:service_accounts/my_project/my_sa`
- `$kms_keys:my_key`
- `$locations:my_location`
- `$notification_channels:my_channel`
- `$project_ids:my_project`
- `$service_account_ids:my_project/my_sa`
- `$service_account_ids:my_project/automation/my_sa`
- `$service_agents:compute`
- `$tag_values:my_value`
- `$vpc_host_projects:my_project`
- `$vpc_sc_perimeters:my_perimeter`

Internally created resources are mapped to context namespaces, and use specific prefixes to express the relationship with their container folder/project where necessary, as shown in the following examples.

### Folder context ids

Folders ids use the `$folder_ids` namespace, with ids derived from the full filesystem path to express the hierarchy.

As an example, the id of the folder defined in `folders/networking/prod/.config.yaml` file will be accessible via `$folder_ids:networking/prod`.

### Project context ids

Project ids ise the `$project_ids:` namespace, with ids defined in two different ways:

- projects defined in the `var.factories_config.project` tree use the filename (dirname is stripped)
- projects defined in the `var.factories_config.folders` tree use the full path (dirname is kept)

As an example, the id of the project defined in the `projects/team-0/app-0-0.yaml` file will be accessible via `$project_ids:app-0-0`. The id of the project defined in the `folders/shared/iac-core-0.yaml` file will be accessible via `$project_ids:shared/iac-core-0`.

### Service account context ids

Service accounts use the `$iam_principals:` namespace, with ids that allow referring to their parent project. As an example, the `rw` service account defined in the `projects/team-0/app-0-0.yaml` file will be accessible via `$iam_principals:service_accounts/app-0-0/rw`.

```yaml
iam_by_principals:
  $iam_principals:service_accounts/app-0-0/rw:
    - roles/viewer
```

Service accounts defined in the `automation` block will have an `automation` prefix prepended to their context id.

```yaml
automation:
  project: $project_ids:prod-iac-core-0
  bucket:
    name: tf-state
  service_accounts:
    ro: {}
    rw:
      iam_sa_roles:
        $service_account_ids:dev-app0-be-0/automation/ro:
          - roles.iam.serviceAccountTokenCreator
```

The only exception is when setting IAM binding for a service account on a different service account via the `iam_sa_roles` attribute, which interpolates using the `$service_account_ids` namespace. As an example, granting a role to the `rw` service account above on the `ro` service account in the same project will use `$service_account_ids:app-0-0/ro`.

```yaml
service_accounts:
  ro: {}
  rw:
    iam_sa_roles:
      $service_account_ids:app-0-0/ro:
        - roles/iam.serviceAccountTokenCreator
```

### Other context ids

Other context ids simply match whatever was passed in via the `var.contexts` variable. The following is a short example.

```hcl
context = {
  custom_roles = {
    myrole = "organizations/1234567890/roles/myRoleOne"
  }
  folder_ids = {
    "test/prod" = "folders/1234567890"
  }
  iam_principals = {
    mysa    = "serviceAccount:test@test-project.iam.gserviceaccount.com"
  }
  project_ids = {
    vpc-host = "test-vpc-host"
  }
  tag_values = {
    "test/one" = "tagValues/1234567890"
  }
  vpc_sc_perimeters = {
    default = "accessPolicies/888933661165/servicePerimeters/default"
  }
}
# tftest: skip
```

```yaml
parent: $folder_ids/test/prod
iam:
  $custom_roles:myrole:
    - $iam_principals:mygroup
shared_vpc_service_config:
  host_project: $project_ids:vpc-host
tag_bindings:
  foo: $tag_values:test/one
vpc_sc:
  perimeter_name: $vpc_sc_perimeters:default
```

## Example

This show a module invocation using all optional features:

```hcl
module "project-factory" {
  source = "./fabric/modules/project-factory"
  context = {
    folder_ids = {
      default = "folders/5678901234"
      teams   = "folders/5678901234"
    }
    kms_keys = {
      compute-prod-ew1 = "projects/kms-central-prj/locations/europe-west1/keyRings/my-keyring/cryptoKeys/ew1-compute"
    }
    iam_principals = {
      gcp-devops = "group:gcp-devops@example.org"
    }
    tag_values = {
      "context/gke"                = "tagValues/654321"
      "org-policies/drs-allow-all" = "tagValues/123456"
    }
    vpc_host_projects = {
      dev-spoke-0 = "test-pf-dev-net-spoke-0"
    }
  }
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
      billing_account_id = var.billing_account_id
      data               = "data/budgets"
    }
    folders           = "data/hierarchy"
    project_templates = "data/templates"
    projects          = "data/projects"
  }
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
# tftest files=t0,0,1,2,3,4,5,6,7,8,9 inventory=example.yaml
```

A project template for GKE projects:

```yaml
services:
  - compute.googleapis.com
  - container.googleapis.com
  - storage.googleapis.com
service_encryption_key_ids:
  storage.googleapis.com:
    - projects/kms-central-prj/locations/europe-west3/keyRings/my-keyring/cryptoKeys/europe3-gce
  compute.googleapis.com:
    - $kms_keys:compute-prod-ew1
tag_bindings:
  context: $tag_values:context/gke
# tftest-file id=t0 path=data/templates/container/base.yaml schema=project.schema.json
```

A simple hierarchy of folders:

```yaml
name: Team A
# implicit parent definition via 'default' key
iam:
  roles/viewer:
    - group:team-a-admins@example.org
    - $iam_principals:gcp-devops
# tftest-file id=0 path=data/hierarchy/team-a/.config.yaml schema=folder.schema.json
```

```yaml
name: Team B
# explicit parent definition via key
parent: $folder_ids:teams
# tftest-file id=1 path=data/hierarchy/team-b/.config.yaml schema=folder.schema.json
```

```yaml
name: Team C
# explicit parent definition via folder id
parent: folders/5678901234
# tftest-file id=2 path=data/hierarchy/team-c/.config.yaml schema=folder.schema.json
```

```yaml
name: App 0
# tftest-file id=3 path=data/hierarchy/team-a/app-0/.config.yaml schema=folder.schema.json
```

```yaml
name: App 0
tag_bindings:
  drs-allow-all: $tag_values:org-policies/drs-allow-all
# tftest-file id=4 path=data/hierarchy/team-b/app-0/.config.yaml schema=folder.schema.json
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
# inherit template attributes
project_template: container/base
# define project attributes (potentially overriding template)
billing_account: 012345-67890A-BCDEF0
labels:
 app: app-0
 team: team-a
parent: $folder_ids:team-a/app-0
iam_by_principals:
  $iam_principals:service_accounts/dev-ta-app0-be/app-0-be:
    - roles/storage.objectViewer
iam:
  roles/cloudkms.cryptoKeyEncrypterDecrypter:
    - $service_agents:storage
service_accounts:
  app-0-be:
    display_name: "Backend instances."
    iam_project_roles:
      $project_ids:dev-spoke-0:
        - roles/compute.networkUser
    iam_self_roles:
      - roles/logging.logWriter
      - roles/monitoring.metricWriter
  app-0-fe:
    display_name: "Frontend instances."
    iam_project_roles:
      $project_ids:dev-spoke-0:
        - roles/compute.networkUser
    iam_self_roles:
      - roles/logging.logWriter
      - roles/monitoring.metricWriter
shared_vpc_service_config:
  host_project: $project_ids:dev-spoke-0
  network_users:
    - $iam_principals:gcp-devops
  service_agent_iam:
    "roles/container.hostServiceAgentUser":
      - $service_agents:container-engine
    "roles/compute.networkUser":
      - $service_agents:container-engine
billing_budgets:
  - $billing_budgets:test-100
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
parent: $folder_ids:team-b/app-0
services:
- run.googleapis.com
- storage.googleapis.com
iam:
  "roles/owner":
    - $iam_principals:service_accounts/dev-tb-app0-0/automation/rw
  "roles/viewer":
    - $iam_principals:service_accounts/dev-tb-app0-0/automation/ro
shared_vpc_host_config:
  enabled: true
service_accounts:
  vm-default:
    display_name: "VM default service account."
    iam_self_roles:
      - roles/logging.logWriter
      - roles/monitoring.metricWriter
    iam:
      roles/iam.serviceAccountTokenCreator:
        - $iam_principals:service_accounts/dev-tb-app0-0/automation/rw
automation:
  project: test-pf-teams-iac-0
  # prefix used for automation resources can be explicitly set if needed
  # prefix: test-pf-dev-tb-0-0
  service_accounts:
    rw:
      description: Team B app 0 read/write automation sa.
    ro:
      description: Team B app 0 read-only automation sa.
  bucket:
    description: Team B app 0 Terraform state bucket.
    iam:
      roles/storage.objectCreator:
        - $iam_principals:service_accounts/dev-tb-app0-0/automation/rw
      roles/storage.objectViewer:
        - $iam_principals:gcp-devops
        - group:team-b-admins@example.org
        - $iam_principals:service_accounts/dev-tb-app0-0/automation/rw
        - $iam_principals:service_accounts/dev-tb-app0-0/automation/ro

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
    - $notification_channels:billing-default
# tftest-file id=8 path=data/budgets/test-100.yaml schema=budget.schema.json
```

Granting permissions to service accounts defined in other project through interpolation:

```yaml
billing_account: 012345-67890A-BCDEF0
labels:
 app: app-0
 team: team-b
parent: $folder_ids:team-b/app-0
services:
  - container.googleapis.com
  - storage.googleapis.com
iam:
  "roles/run.admin":
    - $iam_principals:service_accounts/dev-ta-app0-be/app-0-be
  "roles/run.developer":
    - $iam_principals:service_accounts/dev-tb-app0-1/app-0-be
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

| name | description | modules | resources |
|---|---|---|---|
| [automation.tf](./automation.tf) | None | <code>gcs</code> · <code>iam-service-account</code> |  |
| [budgets.tf](./budgets.tf) | Billing budget factory locals. | <code>billing-account</code> |  |
| [folders.tf](./folders.tf) | Folder hierarchy factory resources. | <code>folder</code> |  |
| [main.tf](./main.tf) | Projects and billing budgets factory resources. |  | <code>terraform_data</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  |  |
| [projects-buckets.tf](./projects-buckets.tf) | None | <code>gcs</code> |  |
| [projects-defaults.tf](./projects-defaults.tf) | None |  |  |
| [projects-log-buckets.tf](./projects-log-buckets.tf) | None | <code>logging-bucket</code> |  |
| [projects-service-accounts.tf](./projects-service-accounts.tf) | None | <code>iam-service-account</code> |  |
| [projects.tf](./projects.tf) | None | <code>project</code> |  |
| [variables-billing.tf](./variables-billing.tf) | None |  |  |
| [variables-folders.tf](./variables-folders.tf) | None |  |  |
| [variables-projects.tf](./variables-projects.tf) | None |  |  |
| [variables.tf](./variables.tf) | Module variables. |  |  |

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [factories_config](variables.tf#L173) | Path to folder with YAML resource description data files. | <code title="object&#40;&#123;&#10;  folders           &#61; optional&#40;string&#41;&#10;  project_templates &#61; optional&#40;string&#41;&#10;  projects          &#61; optional&#40;string&#41;&#10;  budgets &#61; optional&#40;object&#40;&#123;&#10;    billing_account_id &#61; string&#10;    data               &#61; string&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [context](variables.tf#L17) | Context-specific interpolations. | <code title="object&#40;&#123;&#10;  condition_vars        &#61; optional&#40;map&#40;map&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  custom_roles          &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  folder_ids            &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  iam_principals        &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  kms_keys              &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  locations             &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  notification_channels &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  project_ids           &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  tag_values            &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  vpc_host_projects     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  vpc_sc_perimeters     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [data_defaults](variables.tf#L36) | Optional default values used when corresponding project or folder data from files are missing. | <code title="object&#40;&#123;&#10;  billing_account &#61; optional&#40;string&#41;&#10;  bucket &#61; optional&#40;object&#40;&#123;&#10;    force_destroy &#61; optional&#40;bool&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  contacts        &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  deletion_policy &#61; optional&#40;string&#41;&#10;  factories_config &#61; optional&#40;object&#40;&#123;&#10;    custom_roles  &#61; optional&#40;string&#41;&#10;    observability &#61; optional&#40;string&#41;&#10;    org_policies  &#61; optional&#40;string&#41;&#10;    quotas        &#61; optional&#40;string&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  labels        &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  metric_scopes &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  parent        &#61; optional&#40;string&#41;&#10;  prefix        &#61; optional&#40;string&#41;&#10;  project_reuse &#61; optional&#40;object&#40;&#123;&#10;    use_data_source &#61; optional&#40;bool, true&#41;&#10;    attributes &#61; optional&#40;object&#40;&#123;&#10;      name             &#61; string&#10;      number           &#61; number&#10;      services_enabled &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  service_encryption_key_ids &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  services                   &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  shared_vpc_service_config &#61; optional&#40;object&#40;&#123;&#10;    host_project &#61; string&#10;    iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;      member &#61; string&#10;      role   &#61; string&#10;      condition &#61; optional&#40;object&#40;&#123;&#10;        expression  &#61; string&#10;        title       &#61; string&#10;        description &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;    network_users            &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    service_agent_iam        &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;    service_agent_subnet_iam &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;    service_iam_grants       &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    network_subnet_users     &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;&#41;&#10;  storage_location &#61; optional&#40;string&#41;&#10;  tag_bindings     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  service_accounts &#61; optional&#40;map&#40;object&#40;&#123;&#10;    display_name   &#61; optional&#40;string, &#34;Terraform-managed.&#34;&#41;&#10;    iam_self_roles &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  universe &#61; optional&#40;object&#40;&#123;&#10;    prefix                         &#61; string&#10;    unavailable_service_identities &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    unavailable_services           &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;&#41;&#10;  vpc_sc &#61; optional&#40;object&#40;&#123;&#10;    perimeter_name &#61; string&#10;    is_dry_run     &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;&#41;&#10;  logging_data_access &#61; optional&#40;map&#40;object&#40;&#123;&#10;    ADMIN_READ &#61; optional&#40;object&#40;&#123; exempted_members &#61; optional&#40;list&#40;string&#41;&#41; &#125;&#41;&#41;,&#10;    DATA_READ  &#61; optional&#40;object&#40;&#123; exempted_members &#61; optional&#40;list&#40;string&#41;&#41; &#125;&#41;&#41;,&#10;    DATA_WRITE &#61; optional&#40;object&#40;&#123; exempted_members &#61; optional&#40;list&#40;string&#41;&#41; &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [data_merges](variables.tf#L108) | Optional values that will be merged with corresponding data from files. Combines with `data_defaults`, file data, and `data_overrides`. | <code title="object&#40;&#123;&#10;  contacts                   &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  labels                     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  metric_scopes              &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  service_encryption_key_ids &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  services                   &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  tag_bindings               &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  service_accounts &#61; optional&#40;map&#40;object&#40;&#123;&#10;    display_name   &#61; optional&#40;string, &#34;Terraform-managed.&#34;&#41;&#10;    iam_self_roles &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [data_overrides](variables.tf#L127) | Optional values that override corresponding data from files. Takes precedence over file data and `data_defaults`. | <code title="object&#40;&#123;&#10;  billing_account &#61; optional&#40;string&#41;&#10;  bucket &#61; optional&#40;object&#40;&#123;&#10;    force_destroy &#61; optional&#40;bool&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  contacts        &#61; optional&#40;map&#40;list&#40;string&#41;&#41;&#41;&#10;  deletion_policy &#61; optional&#40;string&#41;&#10;  factories_config &#61; optional&#40;object&#40;&#123;&#10;    custom_roles  &#61; optional&#40;string&#41;&#10;    observability &#61; optional&#40;string&#41;&#10;    org_policies  &#61; optional&#40;string&#41;&#10;    quotas        &#61; optional&#40;string&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  parent                     &#61; optional&#40;string&#41;&#10;  prefix                     &#61; optional&#40;string&#41;&#10;  service_encryption_key_ids &#61; optional&#40;map&#40;list&#40;string&#41;&#41;&#41;&#10;  storage_location           &#61; optional&#40;string&#41;&#10;  tag_bindings               &#61; optional&#40;map&#40;string&#41;&#41;&#10;  services                   &#61; optional&#40;list&#40;string&#41;&#41;&#10;  service_accounts &#61; optional&#40;map&#40;object&#40;&#123;&#10;    display_name   &#61; optional&#40;string, &#34;Terraform-managed.&#34;&#41;&#10;    iam_self_roles &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;&#41;&#10;  universe &#61; optional&#40;object&#40;&#123;&#10;    prefix                         &#61; string&#10;    unavailable_service_identities &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    unavailable_services           &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;&#41;&#10;  vpc_sc &#61; optional&#40;object&#40;&#123;&#10;    perimeter_name &#61; string&#10;    is_dry_run     &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;&#41;&#10;  logging_data_access &#61; optional&#40;map&#40;object&#40;&#123;&#10;    ADMIN_READ &#61; optional&#40;object&#40;&#123; exempted_members &#61; optional&#40;list&#40;string&#41;&#41; &#125;&#41;&#41;,&#10;    DATA_READ  &#61; optional&#40;object&#40;&#123; exempted_members &#61; optional&#40;list&#40;string&#41;&#41; &#125;&#41;&#41;,&#10;    DATA_WRITE &#61; optional&#40;object&#40;&#123; exempted_members &#61; optional&#40;list&#40;string&#41;&#41; &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [folders](variables-folders.tf#L17) | Folders data merged with factory data. | <code title="map&#40;object&#40;&#123;&#10;  name   &#61; optional&#40;string&#41;&#10;  parent &#61; optional&#40;string&#41;&#10;  iam    &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;    members &#61; list&#40;string&#41;&#10;    role    &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;    member &#61; string&#10;    role   &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  iam_by_principals &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  tag_bindings      &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [notification_channels](variables-billing.tf#L17) | Notification channels used by budget alerts. | <code title="map&#40;object&#40;&#123;&#10;  project_id   &#61; string&#10;  type         &#61; string&#10;  description  &#61; optional&#40;string&#41;&#10;  display_name &#61; optional&#40;string&#41;&#10;  enabled      &#61; optional&#40;bool, true&#41;&#10;  force_delete &#61; optional&#40;bool&#41;&#10;  labels       &#61; optional&#40;map&#40;string&#41;&#41;&#10;  sensitive_labels &#61; optional&#40;list&#40;object&#40;&#123;&#10;    auth_token  &#61; optional&#40;string&#41;&#10;    password    &#61; optional&#40;string&#41;&#10;    service_key &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#41;&#10;  user_labels &#61; optional&#40;map&#40;string&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [projects](variables-projects.tf#L17) | Projects data merged with factory data. | <code title="map&#40;object&#40;&#123;&#10;  automation &#61; optional&#40;object&#40;&#123;&#10;    project &#61; string&#10;    bucket &#61; optional&#40;object&#40;&#123;&#10;      location                    &#61; string&#10;      description                 &#61; optional&#40;string&#41;&#10;      force_destroy               &#61; optional&#40;bool&#41;&#10;      prefix                      &#61; optional&#40;string&#41;&#10;      storage_class               &#61; optional&#40;string, &#34;STANDARD&#34;&#41;&#10;      uniform_bucket_level_access &#61; optional&#40;bool, true&#41;&#10;      versioning                  &#61; optional&#40;bool&#41;&#10;      iam                         &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;      iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;        members &#61; list&#40;string&#41;&#10;        role    &#61; string&#10;        condition &#61; optional&#40;object&#40;&#123;&#10;          expression  &#61; string&#10;          title       &#61; string&#10;          description &#61; optional&#40;string&#41;&#10;        &#125;&#41;&#41;&#10;      &#125;&#41;&#41;, &#123;&#125;&#41;&#10;      iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;        member &#61; string&#10;        role   &#61; string&#10;        condition &#61; optional&#40;object&#40;&#123;&#10;          expression  &#61; string&#10;          title       &#61; string&#10;          description &#61; optional&#40;string&#41;&#10;        &#125;&#41;&#41;&#10;      &#125;&#41;&#41;, &#123;&#125;&#41;&#10;      labels &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;      managed_folders &#61; optional&#40;map&#40;object&#40;&#123;&#10;        force_destroy &#61; optional&#40;bool&#41;&#10;        iam           &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;        iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;          members &#61; list&#40;string&#41;&#10;          role    &#61; string&#10;          condition &#61; optional&#40;object&#40;&#123;&#10;            expression  &#61; string&#10;            title       &#61; string&#10;            description &#61; optional&#40;string&#41;&#10;          &#125;&#41;&#41;&#10;        &#125;&#41;&#41;, &#123;&#125;&#41;&#10;        iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;          member &#61; string&#10;          role   &#61; string&#10;          condition &#61; optional&#40;object&#40;&#123;&#10;            expression  &#61; string&#10;            title       &#61; string&#10;            description &#61; optional&#40;string&#41;&#10;          &#125;&#41;&#41;&#10;        &#125;&#41;&#41;, &#123;&#125;&#41;&#10;      &#125;&#41;&#41;, &#123;&#125;&#41;&#10;    &#125;&#41;&#41;&#10;    service_accounts &#61; optional&#40;map&#40;object&#40;&#123;&#10;      description &#61; optional&#40;string&#41;&#10;      iam         &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;      iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;        members &#61; list&#40;string&#41;&#10;        role    &#61; string&#10;        condition &#61; optional&#40;object&#40;&#123;&#10;          expression  &#61; string&#10;          title       &#61; string&#10;          description &#61; optional&#40;string&#41;&#10;        &#125;&#41;&#41;&#10;      &#125;&#41;&#41;, &#123;&#125;&#41;&#10;      iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;        member &#61; string&#10;        role   &#61; string&#10;        condition &#61; optional&#40;object&#40;&#123;&#10;          expression  &#61; string&#10;          title       &#61; string&#10;          description &#61; optional&#40;string&#41;&#10;        &#125;&#41;&#41;&#10;      &#125;&#41;&#41;, &#123;&#125;&#41;&#10;      iam_billing_roles      &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;      iam_folder_roles       &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;      iam_organization_roles &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;      iam_project_roles      &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;      iam_sa_roles           &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;      iam_storage_roles      &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;&#41;&#10;  billing_account &#61; optional&#40;string&#41;&#10;  billing_budgets &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  buckets &#61; optional&#40;map&#40;object&#40;&#123;&#10;    location                    &#61; string&#10;    description                 &#61; optional&#40;string&#41;&#10;    force_destroy               &#61; optional&#40;bool&#41;&#10;    prefix                      &#61; optional&#40;string&#41;&#10;    storage_class               &#61; optional&#40;string, &#34;STANDARD&#34;&#41;&#10;    uniform_bucket_level_access &#61; optional&#40;bool, true&#41;&#10;    versioning                  &#61; optional&#40;bool&#41;&#10;    iam                         &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;    iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;      members &#61; list&#40;string&#41;&#10;      role    &#61; string&#10;      condition &#61; optional&#40;object&#40;&#123;&#10;        expression  &#61; string&#10;        title       &#61; string&#10;        description &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;    iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;      member &#61; string&#10;      role   &#61; string&#10;      condition &#61; optional&#40;object&#40;&#123;&#10;        expression  &#61; string&#10;        title       &#61; string&#10;        description &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;    labels &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;    managed_folders &#61; optional&#40;map&#40;object&#40;&#123;&#10;      force_destroy &#61; optional&#40;bool&#41;&#10;      iam           &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;      iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;        members &#61; list&#40;string&#41;&#10;        role    &#61; string&#10;        condition &#61; optional&#40;object&#40;&#123;&#10;          expression  &#61; string&#10;          title       &#61; string&#10;          description &#61; optional&#40;string&#41;&#10;        &#125;&#41;&#41;&#10;      &#125;&#41;&#41;, &#123;&#125;&#41;&#10;      iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;        member &#61; string&#10;        role   &#61; string&#10;        condition &#61; optional&#40;object&#40;&#123;&#10;          expression  &#61; string&#10;          title       &#61; string&#10;          description &#61; optional&#40;string&#41;&#10;        &#125;&#41;&#41;&#10;      &#125;&#41;&#41;, &#123;&#125;&#41;&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  contacts &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  iam      &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;    members &#61; list&#40;string&#41;&#10;    role    &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;    member &#61; string&#10;    role   &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  iam_by_principals &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  labels            &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  metric_scopes     &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  name              &#61; optional&#40;string&#41;&#10;  org_policies &#61; optional&#40;map&#40;object&#40;&#123;&#10;    inherit_from_parent &#61; optional&#40;bool&#41; &#35; for list policies only.&#10;    reset               &#61; optional&#40;bool&#41;&#10;    rules &#61; optional&#40;list&#40;object&#40;&#123;&#10;      allow &#61; optional&#40;object&#40;&#123;&#10;        all    &#61; optional&#40;bool&#41;&#10;        values &#61; optional&#40;list&#40;string&#41;&#41;&#10;      &#125;&#41;&#41;&#10;      deny &#61; optional&#40;object&#40;&#123;&#10;        all    &#61; optional&#40;bool&#41;&#10;        values &#61; optional&#40;list&#40;string&#41;&#41;&#10;      &#125;&#41;&#41;&#10;      enforce &#61; optional&#40;bool&#41; &#35; for boolean policies only.&#10;      condition &#61; optional&#40;object&#40;&#123;&#10;        description &#61; optional&#40;string&#41;&#10;        expression  &#61; optional&#40;string&#41;&#10;        location    &#61; optional&#40;string&#41;&#10;        title       &#61; optional&#40;string&#41;&#10;      &#125;&#41;, &#123;&#125;&#41;&#10;      parameters &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  parent &#61; optional&#40;string&#41;&#10;  prefix &#61; optional&#40;string&#41;&#10;  service_accounts &#61; optional&#40;map&#40;object&#40;&#123;&#10;    display_name      &#61; optional&#40;string&#41;&#10;    iam_self_roles    &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    iam_project_roles &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  service_encryption_key_ids &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  services                   &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  shared_vpc_host_config &#61; optional&#40;object&#40;&#123;&#10;    enabled          &#61; bool&#10;    service_projects &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;&#41;&#10;  shared_vpc_service_config &#61; optional&#40;object&#40;&#123;&#10;    host_project             &#61; string&#10;    network_users            &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    service_agent_iam        &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;    service_agent_subnet_iam &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;    service_iam_grants       &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    network_subnet_users     &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;&#41;&#10;  tag_bindings &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  universe &#61; optional&#40;object&#40;&#123;&#10;    prefix                         &#61; string&#10;    unavailable_services           &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    unavailable_service_identities &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;&#41;&#10;  vpc_sc &#61; optional&#40;object&#40;&#123;&#10;    perimeter_name &#61; string&#10;    is_dry_run     &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [folder_ids](outputs.tf#L78) | Folder ids. |  |
| [iam_principals](outputs.tf#L83) | IAM principals mappings. |  |
| [log_buckets](outputs.tf#L88) | Log bucket ids. |  |
| [project_ids](outputs.tf#L95) | Project ids. |  |
| [project_numbers](outputs.tf#L100) | Project numbers. |  |
| [projects](outputs.tf#L107) | Project attributes. |  |
| [service_account_emails](outputs.tf#L112) | Service account emails. |  |
| [service_account_iam_emails](outputs.tf#L119) | Service account IAM-format emails. |  |
| [service_account_ids](outputs.tf#L126) | Service account IDs. |  |
| [service_accounts](outputs.tf#L133) | Service account emails. |  |
| [storage_buckets](outputs.tf#L138) | Bucket names. |  |
<!-- END TFDOC -->
## Tests

These tests validate fixes to the project factory.

```hcl
module "project-factory" {
  source = "./fabric/modules/project-factory"
  data_defaults = {
    billing_account  = "012345-67890A-ABCDEF"
    storage_location = "eu"
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
    projects = "data/projects"
  }
}
# tftest modules=4 resources=23 files=test-0,test-1,test-2
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
