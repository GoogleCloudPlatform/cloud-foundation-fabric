# Google Cloud Storage Module

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required |
|---|---|:---: |:---:|
| names | Bucket name suffixes. | `list(string)` | ✓
| project_id | Bucket project id. | `string` | ✓
| *bucket_policy_only* | Optional map to disable object ACLS keyed by name, defaults to true. | `map(bool)` | 
| *force_destroy* | Optional map to set force destroy keyed by name, defaults to false. | `map(bool)` | 
| *iam_members* | List of IAM members keyed by name and role. | `map(map(list(string)))` | 
| *iam_roles* | List of IAM roles keyed by name. | `map(list(string))` | 
| *labels* | Labels to be attached to all buckets. | `map(string)` | 
| *location* | Bucket location. | `string` | 
| *prefix* | Prefix used to generate the bucket name. | `string` | 
| *storage_class* | Bucket storage class. | `string` | 
| *versioning* | Optional map to set versioning keyed by name, defaults to false. | `map(bool)` | 

## Outputs

| name | description | sensitive |
|---|---|:---:|
| bucket | Bucket resource (for single use). |  |
| buckets | Bucket resources. |  |
| name | Bucket name (for single use). |  |
| names | Bucket names. |  |
| names_list | List of bucket names. |  |
| url | Bucket URL (for single use). |  |
| urls | Bucket URLs. |  |
| urls_list | List of bucket URLs. |  |
<!-- END TFDOC -->
