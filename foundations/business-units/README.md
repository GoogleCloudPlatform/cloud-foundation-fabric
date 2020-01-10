# Business-units based organizational sample

This sample creates an organizational layout with two folder levels, where the first level is usually mapped to one business unit or team (infra, data, analytics) and the second level represents enviroments (prod, test). It also sets up all prerequisites for automation (GCS state buckets, service accounts, etc.), and the correct roles on those to enforce separation of duties at the environment level.

This layout is well suited for medium-sized infrastructures managed by different sets of teams, and especially where the foundational infrastructure needs to be managed centrally, as the top-level automation service accounts for each environment allow cross-team management of the base resources (projects, IAM, etc.).

![High-level diagram](diagram.png "High-level diagram")

Refer to the [section-level README](../README.md) for general considerations about this type of samples, and usage instructions.

## Managed resources and services

This sample creates several distinct groups of resources:

- one top-level folder per business unit/team
- one top-level folder for shared services
- one second-level folder for each environment in all the business unit top-level folders
- one project in the shared folder to hold Terraform-related resources
- one project in the shared folder to set up and host centralized audit log exports
- one project in the shared folder to hold services used across environments like GCS, GCR, KMS, Cloud Build, etc.

The number of resources in this sample is kept to a minimum so as to make it generally applicable, more resources can be easily added by leveraging the full array of [Cloud Foundation Toolkit modules](https://github.com/terraform-google-modules), especially in the shared services project.

## Shared services

This sample uses a top-level folder to encapsulate projects that host resources that are not specific to a single environment. If no shared services are needed,the Terraform and audit modules can be easily attached to the root node, and the shared services folder and project removed from `main.tf`.

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| billing_account_id | Billing account id used as default for new projects. | <code title="">string</code> | ✓ |  |
| business_unit_1_name | Business unit 1 short name. | <code title="">string</code> | ✓ |  |
| business_unit_2_name | Business unit 2 short name. | <code title="">string</code> | ✓ |  |
| business_unit_3_name | Business unit 3 short name. | <code title="">string</code> | ✓ |  |
| environments | Environment short names. | <code title="list&#40;string&#41;">list(string)</code> | ✓ |  |
| organization_id | Organization id. | <code title="">string</code> | ✓ |  |
| prefix | Prefix used for resources that need unique names. | <code title="">string</code> | ✓ |  |
| root_node | Root node for the new hierarchy, either 'organizations/org_id' or 'folders/folder_id'. | <code title="">string</code> | ✓ |  |
| *audit_viewers* | Audit project viewers, in IAM format. | <code title=""></code> |  | <code title="">[]</code> |
| *gcs_location* | GCS bucket location. | <code title=""></code> |  | <code title="">EU</code> |
| *generate_service_account_keys* | Generate and store service account keys in the state file. | <code title=""></code> |  | <code title="">false</code> |
| *project_services* | Service APIs enabled by default in new projects. | <code title=""></code> |  | <code title="&#91;&#10;&#34;resourceviews.googleapis.com&#34;,&#10;&#34;stackdriver.googleapis.com&#34;,&#10;&#93;">...</code> |
| *shared_bindings_members* | List of comma-delimited IAM-format members for the additional shared project bindings. | <code title=""></code> |  | <code title="">[]</code> |
| *shared_bindings_roles* | List of roles for additional shared project bindings. | <code title=""></code> |  | <code title="">[]</code> |
| *terraform_owners* | Terraform project owners, in IAM format. | <code title=""></code> |  | <code title="">[]</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| audit_logs_bq_dataset | Bigquery dataset for the audit logs export. |  |
| audit_logs_project | Project that holds the audit logs export resources. |  |
| bootstrap_tf_gcs_bucket | GCS bucket used for the bootstrap Terraform state. |  |
| business_unit_1_environment_folders_ids | Business unit 1 environment folders. |  |
| business_unit_1_folder_id | Business unit 1 top-level folder ID. |  |
| business_unit_2_environment_folders_ids | Business unit 2 environment folders. |  |
| business_unit_2_folder_id | Business unit 2 top-level folder ID. |  |
| business_unit_3_environment_folders_ids | Business unit 3 environment folders. |  |
| business_unit_3_folder_id | Business unit 3 top-level folder ID. |  |
| environment_service_account_keys | Service account keys used to run each environment Terraform modules. | ✓ |
| environment_service_accounts | Service accounts used to run each environment Terraform modules. |  |
| environment_tf_gcs_buckets | GCS buckets used for each environment Terraform state. |  |
| shared_folder_id | Shared folder ID. |  |
| shared_resources_project | Project that holdes resources shared across business units. |  |
| terraform_project | Project that holds the base Terraform resources. |  |
<!-- END TFDOC -->
