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

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| audit\_viewers | Audit project viewers, in IAM format. | list | `<list>` | no |
| billing\_account\_id | Billing account id used as default for new projects. | string | n/a | yes |
| business\_unit\_1\_name | Business unit 1 short name. | string | n/a | yes |
| business\_unit\_2\_name | Business unit 2 short name. | string | n/a | yes |
| business\_unit\_3\_name | Business unit 3 short name. | string | n/a | yes |
| environments | Environment short names. | list(string) | n/a | yes |
| gcs\_location | GCS bucket location. | string | `"EU"` | no |
| generate\_service\_account\_keys | Generate and store service account keys in the state file. | string | `"false"` | no |
| organization\_id | Organization id. | string | n/a | yes |
| prefix | Prefix used for resources that need unique names. | string | n/a | yes |
| project\_services | Service APIs enabled by default in new projects. | list | `<list>` | no |
| root\_node | Root node for the new hierarchy, either 'organizations/org_id' or 'folders/folder_id'. | string | n/a | yes |
| shared\_bindings\_members | List of comma-delimited IAM-format members for the additional shared project bindings. | list | `<list>` | no |
| shared\_bindings\_roles | List of roles for additional shared project bindings. | list | `<list>` | no |
| terraform\_owners | Terraform project owners, in IAM format. | list | `<list>` | no |

## Outputs

| Name | Description |
|------|-------------|
| audit\_logs\_bq\_dataset | Bigquery dataset for the audit logs export. |
| audit\_logs\_project | Project that holds the audit logs export resources. |
| bootstrap\_tf\_gcs\_bucket | GCS bucket used for the bootstrap Terraform state. |
| business\_unit\_1\_environment\_folders\_ids | Business unit 1 environment folders. |
| business\_unit\_1\_folder\_id | Business unit 1 top-level folder ID. |
| business\_unit\_2\_environment\_folders\_ids | Business unit 2 environment folders. |
| business\_unit\_2\_folder\_id | Business unit 2 top-level folder ID. |
| business\_unit\_3\_environment\_folders\_ids | Business unit 3 environment folders. |
| business\_unit\_3\_folder\_id | Business unit 3 top-level folder ID. |
| environment\_service\_account\_keys | Service account keys used to run each environment Terraform modules. |
| environment\_service\_accounts | Service accounts used to run each environment Terraform modules. |
| environment\_tf\_gcs\_buckets | GCS buckets used for each environment Terraform state. |
| shared\_folder\_id | Shared folder ID. |
| shared\_resources\_project | Project that holdes resources shared across business units. |
| terraform\_project | Project that holds the base Terraform resources. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
