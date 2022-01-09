# Google Cloud Storage Module
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
### Minimal example with GCS notifications
```hcl
module "bucket-gcs-notification" {
  source     = "./modules/gcs"
  project_id = "myproject"
  prefix     = "test"
  name       = "my-bucket"
  notification_config = {
    enabled           = true
    payload_format    = "JSON_API_V1"
    sa_email          = "service-<project-number>@gs-project-accounts.iam.gserviceaccount.com" # GCS SA email must be passed or fetched from projects module.
    topic_name        = "gcs-notification-topic"
    event_types       = ["OBJECT_FINALIZE"]
    custom_attributes = {}
  }
}
# tftest:modules=1:resources=4
```


<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| name | Bucket name suffix. | <code>string</code> | ✓ |  |
| project_id | Bucket project id. | <code>string</code> | ✓ |  |
| cors | CORS configuration for the bucket. Defaults to null. | <code title="object&#40;&#123;&#10;  origin          &#61; list&#40;string&#41;&#10;  method          &#61; list&#40;string&#41;&#10;  response_header &#61; list&#40;string&#41;&#10;  max_age_seconds &#61; number&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| encryption_key | KMS key that will be used for encryption. | <code>string</code> |  | <code>null</code> |
| force_destroy | Optional map to set force destroy keyed by name, defaults to false. | <code>bool</code> |  | <code>false</code> |
| iam | IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| labels | Labels to be attached to all buckets. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| lifecycle_rule | Bucket lifecycle rule | <code title="object&#40;&#123;&#10;  action &#61; object&#40;&#123;&#10;    type          &#61; string&#10;    storage_class &#61; string&#10;  &#125;&#41;&#10;  condition &#61; object&#40;&#123;&#10;    age                        &#61; number&#10;    created_before             &#61; string&#10;    with_state                 &#61; string&#10;    matches_storage_class      &#61; list&#40;string&#41;&#10;    num_newer_versions         &#61; string&#10;    custom_time_before         &#61; string&#10;    days_since_custom_time     &#61; string&#10;    days_since_noncurrent_time &#61; string&#10;    noncurrent_time_before     &#61; string&#10;  &#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| location | Bucket location. | <code>string</code> |  | <code>&#34;EU&#34;</code> |
| logging_config | Bucket logging configuration. | <code title="object&#40;&#123;&#10;  log_bucket        &#61; string&#10;  log_object_prefix &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| notification_config | GCS Notification configuration. | <code title="object&#40;&#123;&#10;  enabled           &#61; bool&#10;  payload_format    &#61; string&#10;  topic_name        &#61; string&#10;  sa_email          &#61; string&#10;  event_types       &#61; list&#40;string&#41;&#10;  custom_attributes &#61; map&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| prefix | Prefix used to generate the bucket name. | <code>string</code> |  | <code>null</code> |
| retention_policy | Bucket retention policy. | <code title="object&#40;&#123;&#10;  retention_period &#61; number&#10;  is_locked        &#61; bool&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| storage_class | Bucket storage class. | <code>string</code> |  | <code>&#34;MULTI_REGIONAL&#34;</code> |
| uniform_bucket_level_access | Allow using object ACLs (false) or not (true, this is the recommended behavior) , defaults to true (which is the recommended practice, but not the behavior of storage API). | <code>bool</code> |  | <code>true</code> |
| versioning | Enable versioning, defaults to false. | <code>bool</code> |  | <code>false</code> |
| website | Bucket website. | <code title="object&#40;&#123;&#10;  main_page_suffix &#61; string&#10;  not_found_page   &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| bucket | Bucket resource. |  |
| name | Bucket name. |  |
| notification | GCS Notification self link. |  |
| topic | Topic ID used by GCS. |  |
| url | Bucket URL. |  |

<!-- END TFDOC -->

