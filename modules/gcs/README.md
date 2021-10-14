# Google Cloud Storage Module

## TODO

- [ ] add support for defining [notifications](https://www.terraform.io/docs/providers/google/r/storage_notification.html)

## Example

```hcl
module "bucket" {
  source     = "./modules/gcs"
  project_id = "myproject"
  prefix     = "test"
  name       = "my-bucket"
  iam = {
    "roles/storage.admin" = ["group:storage@example.com"]
  }
}
# tftest:modules=1:resources=2
```

### Example with Cloud KMS

```hcl
module "bucket" {
  source     = "./modules/gcs"
  project_id = "myproject"
  prefix     = "test"
  name       = "my-bucket"
  iam = {
    "roles/storage.admin" = ["group:storage@example.com"]
  }
  encryption_key = "my-encryption-key"
}
# tftest:modules=1:resources=2
```

### Example with retention policy

```hcl
module "bucket" {
  source     = "./modules/gcs"
  project_id = "myproject"
  prefix     = "test"
  name       = "my-bucket"
  iam = {
    "roles/storage.admin" = ["group:storage@example.com"]
  }

  retention_policy = {
    retention_period = 100
    is_locked        = true
  }

  logging_config = {
    log_bucket        = var.bucket
    log_object_prefix = null
  }
}
# tftest:modules=1:resources=2
```

### Example with lifecycle rule

```hcl
module "bucket" {
  source     = "./modules/gcs"
  project_id = "myproject"
  prefix     = "test"
  name      = "my-bucket"

  iam = {
    "roles/storage.admin" = ["group:storage@example.com"]
  }

  lifecycle_rule = {
    action = {
      type          = "SetStorageClass"
      storage_class = "STANDARD"
    }
    condition = {
      age                        = 30
      created_before             = null
      with_state                 = null
      matches_storage_class      = null
      num_newer_versions         = null
      custom_time_before         = null
      days_since_custom_time     = null
      days_since_noncurrent_time = null
      noncurrent_time_before     = null
    }
  }
}
# tftest:modules=1:resources=2
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| name | Bucket name suffix. | <code title="">string</code> | ✓ |  |
| project_id | Bucket project id. | <code title="">string</code> | ✓ |  |
| *cors* | CORS configuration for the bucket. Defaults to null. | <code title="object&#40;&#123;&#10;origin          &#61; list&#40;string&#41;&#10;method          &#61; list&#40;string&#41;&#10;response_header &#61; list&#40;string&#41;&#10;max_age_seconds &#61; number&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |
| *encryption_key* | KMS key that will be used for encryption. | <code title="">string</code> |  | <code title="">null</code> |
| *force_destroy* | Optional map to set force destroy keyed by name, defaults to false. | <code title="">bool</code> |  | <code title="">false</code> |
| *iam* | IAM bindings in {ROLE => [MEMBERS]} format. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *labels* | Labels to be attached to all buckets. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *lifecycle_rule* | Bucket lifecycle rule | <code title="object&#40;&#123;&#10;action &#61; object&#40;&#123;&#10;type &#61; string&#10;storage_class &#61; string&#10;&#125;&#41;&#10;condition &#61; object&#40;&#123;&#10;age                        &#61; number&#10;created_before             &#61; string&#10;with_state                 &#61; string&#10;matches_storage_class      &#61; list&#40;string&#41;&#10;num_newer_versions         &#61; string&#10;custom_time_before         &#61; string&#10;days_since_custom_time     &#61; string&#10;days_since_noncurrent_time &#61; string&#10;noncurrent_time_before     &#61; string&#10;&#125;&#41;&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |
| *location* | Bucket location. | <code title="">string</code> |  | <code title="">EU</code> |
| *logging_config* | Bucket logging configuration. | <code title="object&#40;&#123;&#10;log_bucket        &#61; string&#10;log_object_prefix &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |
| *prefix* | Prefix used to generate the bucket name. | <code title="">string</code> |  | <code title="">null</code> |
| *retention_policy* | Bucket retention policy. | <code title="object&#40;&#123;&#10;retention_period &#61; number&#10;is_locked        &#61; bool&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |
| *storage_class* | Bucket storage class. | <code title="">string</code> |  | <code title="MULTI_REGIONAL&#10;validation &#123;&#10;condition     &#61; contains&#40;&#91;&#34;STANDARD&#34;, &#34;MULTI_REGIONAL&#34;, &#34;REGIONAL&#34;, &#34;NEARLINE&#34;, &#34;COLDLINE&#34;, &#34;ARCHIVE&#34;&#93;, var.storage_class&#41;&#10;error_message &#61; &#34;Storage class must be one of STANDARD, MULTI_REGIONAL, REGIONAL, NEARLINE, COLDLINE, ARCHIVE.&#34;&#10;&#125;">...</code> |
| *uniform_bucket_level_access* | Allow using object ACLs (false) or not (true, this is the recommended behavior) , defaults to true (which is the recommended practice, but not the behavior of storage API). | <code title="">bool</code> |  | <code title="">true</code> |
| *versioning* | Enable versioning, defaults to false. | <code title="">bool</code> |  | <code title="">false</code> |
| *website* | Bucket website. | <code title="object&#40;&#123;&#10;main_page_suffix &#61; string&#10;not_found_page   &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| bucket | Bucket resource. |  |
| name | Bucket name. |  |
| url | Bucket URL. |  |
<!-- END TFDOC -->
