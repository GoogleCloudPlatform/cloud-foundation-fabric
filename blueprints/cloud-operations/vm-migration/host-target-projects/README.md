# M4CE(v5) - Host and Target Projects

This blueprint creates a Migrate for Compute Engine (v5) environment deployed on an host project with multiple  [target projects](https://cloud.google.com/migrate/compute-engine/docs/5.0/how-to/enable-services#identifying_your_host_project).

The blueprint is designed to implement a M4CE (v5) environment on-top of complex migration landing environments where VMs have to be migrated to multiple target projects. It also includes the IAM wiring needed to make such scenarios work.

This is the high level diagram:

![High-level diagram](diagram.png "High-level diagram")

## Managed resources and services

This sample creates\updates several distinct groups of resources:

- projects
  - Deploy M4CE host project with [required services](https://cloud.google.com/migrate/compute-engine/docs/5.0/how-to/enable-services#enabling_required_services_on_the_host_project) on a new or existing project.
  - M4CE target project prerequisites deployed on existing projects.
- IAM
  - Create a [service account](https://cloud.google.com/migrate/virtual-machines/docs/5.0/how-to/migrate-connector#step-3) used at runtime by the M4CE connector for data replication
  - Grant [migration admin roles](https://cloud.google.com/migrate/virtual-machines/docs/5.0/how-to/enable-services#using_predefined_roles) to provided user or group
  - Grant [migration viewer role](https://cloud.google.com/migrate/virtual-machines/docs/5.0/how-to/enable-services#using_predefined_roles) to provided user or group
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [migration_admin](variables.tf#L15) | User or group who can create a new M4CE sources and perform all other migration operations, in IAM format (`group:foo@example.com`). | <code>string</code> | ✓ |  |
| [migration_target_projects](variables.tf#L20) | List of target projects for m4ce workload migrations. | <code>list&#40;string&#41;</code> | ✓ |  |
| [migration_viewer](variables.tf#L25) | User or group authorized to retrieve information about M4CE in the Google Cloud Console, in IAM format (`group:foo@example.com`). | <code>string</code> |  | <code>null</code> |
| [project_create](variables.tf#L31) | Parameters for the creation of the new project to host the M4CE backend. | <code title="object&#40;&#123;&#10;  billing_account_id &#61; string&#10;  parent             &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [project_name](variables.tf#L40) | Name of an existing project or of the new project assigned as M4CE host project. | <code>string</code> |  | <code>&#34;m4ce-host-project-000&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [m4ce_gmanaged_service_account](outputs.tf#L15) | Google managed service account created automatically during the migrate connector registration.. It is used by M4CE to perform activities on target projects. |  |
<!-- END TFDOC -->
## Test

```hcl
module "test" {
  source = "./fabric/blueprints/cloud-operations/vm-migration/host-target-projects"
  project_create = {
    billing_account_id = "1234-ABCD-1234"
    parent             = "folders/1234563"
  }
  migration_admin           = "user:admin@example.com"
  migration_viewer          = "user:viewer@example.com"
  migration_target_projects = [module.test-target-project.name]
  depends_on = [
    module.test-target-project
  ]
}

module "test-target-project" {
  source          = "./fabric/modules/project"
  billing_account = "1234-ABCD-1234"
  name            = "test-target-project"
  project_create  = true
}

# tftest modules=5 resources=28
```
