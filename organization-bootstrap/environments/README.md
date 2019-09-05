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
- one top-level project to hold services used across environments like GCS, GCR, KMS, Cloud Build, etc. (optional)

The number of resources in this sample is kept to a minimum so as to make it more generally applicable, further resources can be easily added by leveraging the full array of [Cloud Foundation Toolkit modules](https://github.com/terraform-google-modules), especially in the shared services project.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| audit\_viewers | Audit project viewers, in IAM format. | list | `<list>` | no |
| billing\_account\_id | Billing account id used as default for new projects. | string | n/a | yes |
| environments | Environment short names. | list(string) | n/a | yes |
| gcs\_location | GCS bucket location. | string | `"EU"` | no |
| generate\_service\_account\_keys | Generate and store service account keys in the state file. | string | `"false"` | no |
| grant\_xpn\_roles | Grant roles needed for Shared VPC creation to service accounts. | string | `"true"` | no |
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
| environment\_folders | Top-level environment folders. |
| environment\_service\_account\_keys | Service account keys used to run each environment Terraform modules. |
| environment\_service\_accounts | Service accounts used to run each environment Terraform modules. |
| environment\_tf\_gcs\_buckets | GCS buckets used for each environment Terraform state. |
| shared\_resources\_project | Project that holdes resources shared across environments. |
| terraform\_project | Project that holds the base Terraform resources. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
