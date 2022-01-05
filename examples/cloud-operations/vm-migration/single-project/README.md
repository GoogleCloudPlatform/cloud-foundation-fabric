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


## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| billing_account | Billing account id used as default for new projects. | <code>string</code> | ✓ |  |
| m4ce_project_root | Root node for the m4ce host project. Must be of the form folders/folder_id or organizations/org_id. | <code>string</code> | ✓ |  |
| m4ce_admin_users | List of users authorized to create new M4CE sources and perform all other migration operations, in IAM format. | <code>list&#40;string&#41;</code> | ✓ |  |
| m4ce_project_name | Name of the project dedicated to M4CE as host and target for the migration | <code>string</code> |  | <code>&#34;m4ce-host-project-000&#34;</code> |
| m4ce_project_create | Enable the creation of a new project dedicated to M4CE | <code>bool</code> |  | <code>true</code> |
| m4ce_viewer_users | List of users authorized to retirve information about M4CE in the Google Cloud Console. Intended for users who are performing migrations, but not setting up the system or adding new migration sources, in IAM format. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |