# Business-units based organizational sample

This sample creates an organizational layout with two folder levels, where the first level is usually mapped to one business unit or team (infra, data, analytics) and the second level represents enviroments (prod, test). It also sets up all prerequisites for automation (GCS state buckets, service accounts, etc.), and the correct roles on those to enforce separation of duties at the environment level.

This layout is well suited for medium-sized infrastructures managed by different sets of teams, and in cases where the core infrastructure is managed centrally, as the top-level automation service accounts for each environment allow cross-team management of the base resources (projects, IAM, etc.).

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

The number of resources in this sample is kept to a minimum so as to make it generally applicable, more resources can be easily added by leveraging other [modules from our bundle](../../modules/), or from other sources like the [CFT suite](https://github.com/terraform-google-modules).

## Shared services

This sample uses a top-level folder to encapsulate projects that host resources that are not specific to a single environment. If no shared services are needed,the Terraform and audit modules can be easily attached to the root node, and the shared services folder and project removed from `main.tf`.

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| billing_account_id | Billing account id used as default for new projects. | <code title="">string</code> | ✓ |  |
| organization_id | Organization id in organizations/nnnnnnn format. | <code title="">string</code> | ✓ |  |
| prefix | Prefix used for resources that need unique names. | <code title="">string</code> | ✓ |  |
| root_node | Root node for the new hierarchy, either 'organizations/org_id' or 'folders/folder_id'. | <code title="">string</code> | ✓ |  |
| *audit_filter* | Audit log filter used for the log sink. | <code title="">string</code> |  | <code title="&#60;&#60;END&#10;logName: &#34;&#47;logs&#47;cloudaudit.googleapis.com&#37;2Factivity&#34;&#10;OR&#10;logName: &#34;&#47;logs&#47;cloudaudit.googleapis.com&#37;2Fsystem_event&#34;&#10;END">...</code> |
| *environments* | Environment short names. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="&#123;&#10;dev  &#61; &#34;Development&#34;,&#10;test &#61; &#34;Testing&#34;,&#10;prod &#61; &#34;Production&#34;&#10;&#125;">...</code> |
| *gcs_defaults* | Defaults use for the state GCS buckets. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="&#123;&#10;location      &#61; &#34;EU&#34;&#10;storage_class &#61; &#34;MULTI_REGIONAL&#34;&#10;&#125;">...</code> |
| *iam_audit_viewers* | Audit project viewers, in IAM format. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *iam_shared_owners* | Shared services project owners, in IAM format. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *iam_terraform_owners* | Terraform project owners, in IAM format. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *project_services* | Service APIs enabled by default in new projects. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="&#91;&#10;&#34;container.googleapis.com&#34;,&#10;&#34;stackdriver.googleapis.com&#34;,&#10;&#93;">...</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| audit_logs_project | Project that holds the audit logs export resources. |  |
| bootstrap_tf_gcs_bucket | GCS bucket used for the bootstrap Terraform state. |  |
| bu_business_intelligence | Business Intelligence attributes. |  |
| bu_business_intelligence_keys | Business Intelligence service account keys. | ✓ |
| bu_machine_learning | Machine Learning attributes. |  |
| bu_machine_learning_keys | Machine Learning service account keys. | ✓ |
| shared_folder_id | Shared folder id. |  |
| shared_resources_project | Project that holdes resources shared across business units. |  |
| terraform_project | Project that holds the base Terraform resources. |  |
<!-- END TFDOC -->
