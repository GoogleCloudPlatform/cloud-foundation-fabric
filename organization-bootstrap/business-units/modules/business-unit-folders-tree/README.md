# Two-levels folders tree

This module creates one top-level folder and set of second-level folders, which meant to represent a business unit with set of enviroments underneeth. It also creates per environment GCS bucket and ServiceAccount in a project specified by `tf_project_id` variable. 

This set of Terraform files is usually applied manually by an org-level administrator as a first step, and then reapplied only when a new environment needs to be created or an existing one removed, and serves different purposes:

## Managed resources and services

This sample creates several distinct groups of resources:

- one top level folder
- set of second level folders
- set of GCS buckets, which meant to be used for storing terraform state. 
- set of service accounts and keys, which meant to be used for automating underneeth infrastructure with terraform. 

The number of resources in this sample is kept to a minimum so as to make it generally applicable, more resources can be easily added by leveraging the full array of [Cloud Foundation Toolkit modules](https://github.com/terraform-google-modules), especially in the shared services project.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| billing\_account\_id | Billing account id used as default for new projects. | string | n/a | yes |
| gcs\_location | GCS bucket location. | string | `"EU"` | no |
| generate\_service\_account\_keys | Generate and store service account keys in the state file. | string | `"false"` | no |
| organization\_id | Organization id. | string | n/a | yes |
| prefix | Prefix used for resources that need unique names. | string | n/a | yes |
| root\_node | Root node for the new hierarchy, either 'organizations/org_id' or 'folders/folder_id'. | string | n/a | yes |
| second\_level\_folders\_names | Second level folders names. | list(string) | n/a | yes |
| tf\_project\_id | Id of a project where service accounts and terraform state buckets should be created | string | n/a | yes |
| top\_level\_folder\_name | Top level folder name. | string | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| second\_level\_folders\_ids | Second-level folders IDs. |
| second\_level\_folders\_service\_account\_emails | Service accounts used to run each econd-level folder Terraform modules. |
| second\_level\_folders\_service\_account\_keys | Service account keys used to run each second-level folder Terraform modules. |
| second\_level\_folders\_tf\_gcs\_bucket\_names | GCS buckets used for each second-level folder Terraform state. |
| top\_level\_folder\_id | Top-level folder ID. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
