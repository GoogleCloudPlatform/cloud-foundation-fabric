# Google Cloud Storage Module

## Variables

## Variables

| name | description | type | required |
|---|---|:---: |:---:|
| names | Bucket name suffixes. | list | ✓
| project_id | Bucket project id. | string | ✓
| *bucket_policy_only* | Optional map to disable object ACLS keyed by name, defaults to true. | map |
| *force_destroy* | Optional map to set force destroy keyed by name, defaults to false. | map |
| *iam_members* | List of IAM members keyed by name and role. | map |
| *iam_roles* | List of IAM roles keyed by name. | map |
| *labels* | Labels to be attached to all buckets. | map |
| *location* | Bucket location. | string |
| *prefix* | Prefix used to generate the bucket name. | string |
| *storage_class* | Bucket storage class. | string |
| *versioning* | Optional map to set versioning keyed by name, defaults to false. | map |

## Outputs

| name | description |
|---|---|
| bucket | Bucket resource (for single use). |
| buckets | Bucket resources. |
| name | Bucket name (for single use). |
| names | Bucket names. |
| names_list | List of bucket names. |
| url | Bucket URL (for single use). |
| urls | Bucket URLs. |
| urls_list | List of bucket URLs. |

