# M4CE(v5) - Host and Target Projects with Shared VPC

This example creates a Migrate for Compute Engine (v5) environment deployed on an host project with multiple [target projects](https://cloud.google.com/migrate/compute-engine/docs/5.0/how-to/enable-services#identifying_your_host_project) and shared VPCs.

The example is designed to implement a M4CE (v5) environment on-top of complex migration landing environment where VMs have to be migrated to multiple target projects. In this example targets are alse service projects for a shared VPC. It also includes the IAM wiring needed to make such scenarios work.

This is the high level diagram:

![High-level diagram](diagram.png "High-level diagram")

## Managed resources and services

This sample creates\update several distinct groups of resources:

- projects
  - M4CE host project with [required services](https://cloud.google.com/migrate/compute-engine/docs/5.0/how-to/enable-services#enabling_required_services_on_the_host_project) deployed on a new or existing project. 
  - M4CE target project prerequisites deployed on existing projects. 
- IAM
  - Create a [service account](https://cloud.google.com/migrate/compute-engine/docs/5.0/how-to/migrate-connector#step-3) used at runtime by the M4CE connector for data replication
  - Grant [migration admin roles](https://cloud.google.com/migrate/compute-engine/docs/5.0/how-to/enable-services#using_predefined_roles) to provided user accounts.
  - Grant [migration viewer role](https://cloud.google.com/migrate/compute-engine/docs/5.0/how-to/enable-services#using_predefined_roles) to provided user accounts.
  - Grant [roles on shared VPC](https://cloud.google.com/migrate/compute-engine/docs/5.0/how-to/target-project#configure-permissions) to migration admins


## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| billing_account | Billing account id used as default for new projects. | <code>string</code> | ✓ |  |
| m4ce_project_root | Root node for the m4ce host project. Must be of the form folders/folder_id or organizations/org_id. | <code>string</code> | ✓ |  |
| m4ce_admin_users | List of users authorized to create new M4CE sources and perform all other migration operations, in IAM format. | <code>list&#40;string&#41;</code> | ✓ |  |
| sharedvpc_host_project_name | Name of the shared VPC host project. | <code>string</code> | ✓ |  |
| m4ce_project_name | Name of the project dedicated to M4CE as host and target for the migration | <code>string</code> |  | <code>&#34;m4ce-host-project-000&#34;</code> |
| m4ce_project_create | Enable the creation of a new project dedicated to M4CE | <code>bool</code> |  | <code>true</code> |
| m4ce_viewer_users | List of users authorized to retirve information about M4CE in the Google Cloud Console. Intended for users who are performing migrations, but not setting up the system or adding new migration sources, in IAM format. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| m4ce_target_projects | List of target projects for m4ce workload migrations | <code>list&#40;string&#41;</code> | ✓ |  |

## Manual Steps
Once this example is deployed a the M4CE [default service account](https://cloud.google.com/migrate/compute-engine/docs/5.0/how-to/target-sa-compute-engine#configuring_the_default_service_account) has to be configured to grant the access to the shared VPC and allow the deploy of Compute Engine instances as the result of the migration.
