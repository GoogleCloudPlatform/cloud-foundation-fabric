# Two-level folders tree

This module is a simple wrapper for the [Cloud Foundation Folder module](https://github.com/terraform-google-modules/terraform-google-folders), that manages one folder and one child folder under it, for each name passed in the `environments` variable. It is meant to be used for organizational layouts where a predefined number of folders representing environments, are created as child folders for business units or teams.

For details on how the IAM variables work, please refer to the [Cloud Foundation Folder module](https://github.com/terraform-google-modules/terraform-google-folders).

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
