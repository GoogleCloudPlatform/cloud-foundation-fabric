# M4CE(v5) - Single Project

This sample creates a simple M4CE (v5) environment deployed on a signle [host project](https://cloud.google.com/migrate/compute-engine/docs/5.0/how-to/enable-services#identifying_your_host_project).

The example is designed for quick tests or product demos where it is required to setup a simple and minimal M4CE (v5) environment. It also includes the IAM wiring needed to make such scenarios work.

This is the high level diagram:

![High-level diagram](diagram.png "High-level diagram")

## Managed resources and services

This sample creates several distinct groups of resources:

- projects
  - M4CE host project with [required services](https://cloud.google.com/migrate/compute-engine/docs/5.0/how-to/enable-services#enabling_required_services_on_the_host_project) deployed on a new or existing project. 
- networking
  - Default VPC network
- IAM
  - One [service account](https://cloud.google.com/migrate/compute-engine/docs/5.0/how-to/migrate-connector#step-3) used at runtime by the M4CE connector for data replication
  - Grant [migration admin roles](https://cloud.google.com/migrate/compute-engine/docs/5.0/how-to/enable-services#using_predefined_roles) to admin user accounts
  - Grant [migration viewer role](https://cloud.google.com/migrate/compute-engine/docs/5.0/how-to/enable-services#using_predefined_roles) to viewer user accounts

<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| migration_admin_users | List of users authorized to create new M4CE sources and perform all other migration operations, in IAM format. | <code>list&#40;string&#41;</code> | ✓ |  |
| migration_viewer_users | List of users authorized to retirve information about M4CE in the Google Cloud Console. Intended for users who are performing migrations, but not setting up the system or adding new migration sources, in IAM format. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| project_create | Parameters for the creation of the new project designated as M4CE host and migration landing. | <code title="object&#40;&#123;&#10;  billing_account_id&#61; string&#10;  parent&#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| project_name | Name of an existing project or of the new project assigned as M4CE host and migration landing. | <code>string</code> |  | <code>&#34;m4ce-host-project-000&#34;</code>  |
| vpc_config | VPC parameters for the migration landing network.  | <code title="object&#40;&#123;&#10;  ip_cidr_range&#61; string&#10;  region&#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code>  |  | |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| m4ce_gmanaged_service_account | Google-managed service accounts used by M4CE to operate on target projects. This service account will be created automatically by the migrate connector installation and it might requires additional permissions to be configured manually. ([Configuring permission on target project service account](https://cloud.google.com/migrate/compute-engine/docs/5.0/how-to/target-sa-compute-engine#configuring_the_default_service_account), [Configuring permissions for a shared VPC](https://cloud.google.com/migrate/compute-engine/docs/5.0/how-to/shared-vpc#setting-sa) ) |  |

<!-- END TFDOC -->