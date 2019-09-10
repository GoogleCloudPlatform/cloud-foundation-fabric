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
| business\_unit\_folder\_name | Business Unit Folder name. | string | n/a | yes |
| environments | Environment short names. | list(string) | n/a | yes |
| per\_folder\_admins | List of IAM-style members per folder who will get extended permissions. | list(string) | `<list>` | no |
| root\_node | Root node for the new hierarchy, either 'organizations/org_id' or 'folders/folder_id'. | string | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| business\_unit\_folder\_id | Business Unit Folder ID. |
| environment\_folders\_ids | Environment folders IDs. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
