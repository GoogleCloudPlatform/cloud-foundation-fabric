# Google Cloud Folder Module

## Variables

| name | description | type | required |
|---|---|:---: |:---:|
| parent | Parent in folders/folder_id or organizations/org_id format. | string | ✓
| *iam_members* | List of IAM members keyed by folder name and role. | map | 
| *iam_roles* | List of IAM roles keyed by folder name. | map | 
| *names* | Folder names. | list | 

## Outputs

| name | description |
|---|---|
| folder | Folder resource (for single use). |
| folders | Folder resources. |
| id | Folder id (for single use). |
| ids | Folder ids. |
| ids_list | List of folder ids. |
| name | Folder name (for single use). |
| names | Folder names. |
| names_list | List of folder names. |
