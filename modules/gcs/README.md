# Google Cloud Storage Module

## TODO

- [ ] add support for defining [notifications](https://www.terraform.io/docs/providers/google/r/storage_notification.html)

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

### Example with Cloud KMS

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
  encryption_keys = {
    bucket-two = local.kms_key.self_link,
  }
}
```

### Example with retention policy

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

  retention_policies = {
    bucket-one = { retention_period = 100 , is_locked = true}
    bucket-two = { retention_period = 900 , is_locked = false}
  }

  logging_config = {
    bucket-one = { log_bucket = bucket_name_for_logging , log_object_prefix = null}
    bucket-two = { log_bucket = bucket_name_for_logging , log_object_prefix = "logs_for_bucket_two"}
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
| *encryption_keys* | Per-bucket KMS keys that will be used for encryption. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *force_destroy* | Optional map to set force destroy keyed by name, defaults to false. | <code title="map&#40;bool&#41;">map(bool)</code> |  | <code title="">{}</code> |
| *iam_members* | IAM members keyed by bucket name and role. | <code title="map&#40;map&#40;list&#40;string&#41;&#41;&#41;">map(map(list(string)))</code> |  | <code title="">{}</code> |
| *iam_roles* | IAM roles keyed by bucket name. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *labels* | Labels to be attached to all buckets. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *location* | Bucket location. | <code title="">string</code> |  | <code title="">EU</code> |
| *logging_config* | Per-bucket logging. | <code title="map&#40;object&#40;&#123;&#10;log_bucket        &#61; string&#10;log_object_prefix &#61; string&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |
| *prefix* | Prefix used to generate the bucket name. | <code title="">string</code> |  | <code title="">null</code> |
| *retention_policies* | Per-bucket retention policy. | <code title="map&#40;object&#40;&#123;&#10;retention_period &#61; number&#10;is_locked        &#61; bool&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |
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
