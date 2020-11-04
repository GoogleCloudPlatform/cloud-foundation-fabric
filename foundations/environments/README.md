# Environment-based organizational sample

This sample creates an organizational layout with a single level, where each  folder is usually mapped to one infrastructure environment (test, dev, etc.). It also sets up all prerequisites for automation (GCS state buckets, service accounts, etc.), and the correct roles on those to enforce separation of duties at the environment level.

This layout is well suited for medium-sized infrastructures managed by a small set of teams, where the complexity in application resource ownership and access roles is mostly dealt with at the project level, and/or in the individual services (GKE, Cloud SQL, etc.). Its simplicity also makes it a good starting point for more complex or specialized layouts.

![High-level diagram](diagram.png "High-level diagram")

Refer to the [section-level README](../README.md) for general considerations about this type of samples, and usage instructions.

## Managed resources and services

This sample creates several distinct groups of resources:

- one folder per environment
- one top-level project to hold Terraform-related resources
- one top-level project to set up and host centralized audit log exports (optional)
- one top-level shared services project

The number of resources in this sample is kept to a minimum so as to make it generally applicable, more resources can be easily added by leveraging other [modules from our bundle](../../modules/), or from other sources like the [CFT suite](https://github.com/terraform-google-modules).

## Shared services project

This sample contains a single, top-level project used to host services shared across environments (eg GCS, GCR, KMS, Cloud Build, etc.). In our experience, that is enough for many customers, especially those using this organizational layout.

For more complex setups where multiple shared services projects are needed to encapsulate a larger number of resources, shared services should be treated as an extra environment so that they can be managed by a dedicated set of Terraform files, using a separate service account and GCS bucket, with a folder to contain shared projects.

If no shared services are needed, the shared service project module can of course be removed from `main.tf`.

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| billing_account_id | Billing account id used as to create projects. | <code title="">string</code> | ✓ |  |
| environments | Environment short names. | <code title="set&#40;string&#41;">set(string)</code> | ✓ |  |
| organization_id | Organization id in organizations/nnnnnnnn format. | <code title="">string</code> | ✓ |  |
| prefix | Prefix used for resources that need unique names. | <code title="">string</code> | ✓ |  |
| root_node | Root node for the new hierarchy, either 'organizations/org_id' or 'folders/folder_id'. | <code title="">string</code> | ✓ |  |
| *audit_filter* | Audit log filter used for the log sink. | <code title="">string</code> |  | <code title="&#60;&#60;END&#10;logName: &#34;&#47;logs&#47;cloudaudit.googleapis.com&#37;2Factivity&#34;&#10;OR&#10;logName: &#34;&#47;logs&#47;cloudaudit.googleapis.com&#37;2Fsystem_event&#34;&#10;END">...</code> |
| *gcs_location* | GCS bucket location. | <code title="">string</code> |  | <code title="">EU</code> |
| *iam_audit_viewers* | Audit project viewers, in IAM format. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *iam_billing_config* | Control granting billing user role to service accounts. Target the billing account by default. | <code title="object&#40;&#123;&#10;grant      &#61; bool&#10;target_org &#61; bool&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;grant      &#61; true&#10;target_org &#61; false&#10;&#125;">...</code> |
| *iam_folder_roles* | List of roles granted to each service account on its respective folder (excluding XPN roles). | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="&#91;&#10;&#34;roles&#47;compute.networkAdmin&#34;,&#10;&#34;roles&#47;owner&#34;,&#10;&#34;roles&#47;resourcemanager.folderViewer&#34;,&#10;&#34;roles&#47;resourcemanager.projectCreator&#34;,&#10;&#93;">...</code> |
| *iam_shared_owners* | Shared services project owners, in IAM format. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *iam_terraform_owners* | Terraform project owners, in IAM format. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *iam_xpn_config* | Control granting Shared VPC creation roles to service accounts. Target the root node by default. | <code title="object&#40;&#123;&#10;grant      &#61; bool&#10;target_org &#61; bool&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;grant      &#61; true&#10;target_org &#61; true&#10;&#125;">...</code> |
| *project_services* | Service APIs enabled by default in new projects. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="&#91;&#10;&#34;container.googleapis.com&#34;,&#10;&#34;stackdriver.googleapis.com&#34;,&#10;&#93;">...</code> |
| *service_account_keys* | Generate and store service account keys in the state file. | <code title="">bool</code> |  | <code title="">true</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| audit_logs_bq_dataset | Bigquery dataset for the audit logs export. |  |
| audit_logs_project | Project that holds the audit logs export resources. |  |
| bootstrap_tf_gcs_bucket | GCS bucket used for the bootstrap Terraform state. |  |
| environment_folders | Top-level environment folders. |  |
| environment_service_account_keys | Service account keys used to run each environment Terraform modules. | ✓ |
| environment_service_accounts | Service accounts used to run each environment Terraform modules. |  |
| environment_tf_gcs_buckets | GCS buckets used for each environment Terraform state. |  |
| shared_services_project | Project that holdes resources shared across environments. |  |
| terraform_project | Project that holds the base Terraform resources. |  |
<!-- END TFDOC -->
