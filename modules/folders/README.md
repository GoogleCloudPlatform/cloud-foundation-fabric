# Google Cloud Folder Module

This module allow creation and management of sets of folders sharing a common parent, and their individual IAM bindings.

## Example

```hcl
module "folder" {
  source = "./modules/folder"
  parent = "organizations/1234567890"
  names  = ["Folder one", "Folder two]
  iam_members = {
    "Folder one" = {
      "roles/owner" => ["group:users@example.com"]
    }
  }
  iam_roles = {
    "Folder one" = ["roles/owner"]
  }
}
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| parent | Parent in folders/folder_id or organizations/org_id format. | <code title="">string</code> | ✓ |  |
| *iam_members* | List of IAM members keyed by folder name and role. | <code title="map&#40;map&#40;list&#40;string&#41;&#41;&#41;">map(map(list(string)))</code> |  | <code title="">null</code> |
| *iam_roles* | List of IAM roles keyed by folder name. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">null</code> |
| *names* | Folder names. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| folder | Folder resource (for single use). |  |
| folders | Folder resources. |  |
| id | Folder id (for single use). |  |
| ids | Folder ids. |  |
| ids_list | List of folder ids. |  |
| name | Folder name (for single use). |  |
| names | Folder names. |  |
| names_list | List of folder names. |  |
<!-- END TFDOC -->
