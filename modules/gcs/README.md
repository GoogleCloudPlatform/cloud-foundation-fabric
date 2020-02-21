# Google Cloud Storage Module

## Example

```hcl
module "buckets" {
  source     = "./modules/gcs"
  project_id = "myproject"
  prefix     = "test"
  names      = ["bucket-one", "bucket-two"]
  bucket_policy_only = {
    bucket-one = false
  }
  iam_members = {
    bucket-two = {
      "roles/storage.admin" = ["group:storage@example.com"]
    }
  }
  iam_roles = {
    bucket-two = ["roles/storage.admin"]
  }
}
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| names | Bucket name suffixes. | <code title="list&#40;string&#41;">list(string)</code> | ✓ |  |
| project_id | Bucket project id. | <code title="">string</code> | ✓ |  |
| *bucket_policy_only* | Optional map to disable object ACLS keyed by name, defaults to true. | <code title="map&#40;bool&#41;">map(bool)</code> |  | <code title="">{}</code> |
| *force_destroy* | Optional map to set force destroy keyed by name, defaults to false. | <code title="map&#40;bool&#41;">map(bool)</code> |  | <code title="">{}</code> |
| *iam_members* | IAM members keyed by bucket name and role. | <code title="map&#40;map&#40;list&#40;string&#41;&#41;&#41;">map(map(list(string)))</code> |  | <code title="">null</code> |
| *iam_roles* | IAM roles keyed by bucket name. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">null</code> |
| *labels* | Labels to be attached to all buckets. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *location* | Bucket location. | <code title="">string</code> |  | <code title="">EU</code> |
| *prefix* | Prefix used to generate the bucket name. | <code title="">string</code> |  | <code title=""></code> |
| *storage_class* | Bucket storage class. | <code title="">string</code> |  | <code title="">MULTI_REGIONAL</code> |
| *versioning* | Optional map to set versioning keyed by name, defaults to false. | <code title="map&#40;bool&#41;">map(bool)</code> |  | <code title="">{}</code> |

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
