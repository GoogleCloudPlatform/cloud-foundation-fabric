# Google Cloud Storage Module

## Example

```hcl
module "bucket" {
  source     = "./fabric/modules/gcs"
  project_id = "myproject"
  prefix     = "test"
  name       = "my-bucket"
  versioning = true
  labels = {
    cost-center = "devops"
  }
}
# tftest modules=1 resources=1 inventory=simple.yaml
```

### Example with Cloud KMS

```hcl
module "bucket" {
  source         = "./fabric/modules/gcs"
  project_id     = "myproject"
  name           = "my-bucket"
  encryption_key = "my-encryption-key"
}
# tftest modules=1 resources=1 inventory=cmek.yaml
```

### Example with retention policy and logging

```hcl
module "bucket" {
  source     = "./fabric/modules/gcs"
  project_id = "myproject"
  name       = "my-bucket"
  retention_policy = {
    retention_period = 100
    is_locked        = true
  }
  logging_config = {
    log_bucket        = "log-bucket"
    log_object_prefix = null
  }
}
# tftest modules=1 resources=1 inventory=retention-logging.yaml
```

### Example with lifecycle rule

```hcl
module "bucket" {
  source     = "./fabric/modules/gcs"
  project_id = "myproject"
  name       = "my-bucket"
  lifecycle_rules = {
    lr-0 = {
      action = {
        type          = "SetStorageClass"
        storage_class = "STANDARD"
      }
      condition = {
        age = 30
      }
    }
  }
}
# tftest modules=1 resources=1 inventory=lifecycle.yaml
```

### Minimal example with GCS notifications

```hcl
module "bucket-gcs-notification" {
  source     = "./fabric/modules/gcs"
  project_id = "myproject"
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
# tftest modules=1 resources=4 inventory=notification.yaml
```

### Example with object upload

```hcl
module "bucket" {
  source     = "./fabric/modules/gcs"
  project_id = "myproject"
  name       = "my-bucket"
  objects_to_upload = {
    sample-data = {
      name         = "example-file.csv"
      source       = "data/example-file.csv"
      content_type = "text/csv"
    }
  }
}
# tftest modules=1 resources=2 inventory=object-upload.yaml
```

### Examples of IAM

```hcl
module "bucket" {
  source     = "./fabric/modules/gcs"
  project_id = "myproject"
  name       = "my-bucket"
  iam = {
    "roles/storage.admin" = ["group:storage@example.com"]
  }
}
# tftest modules=1 resources=2 inventory=iam-authoritative.yaml
```

```hcl
module "bucket" {
  source     = "./fabric/modules/gcs"
  project_id = "myproject"
  name       = "my-bucket"
  iam_bindings = {
    storage-admin-with-delegated_roles = {
      role    = "roles/storage.admin"
      members = ["group:storage@example.com"]
      condition = {
        title = "delegated-role-grants"
        expression = format(
          "api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly([%s])",
          join(",", formatlist("'%s'",
            [
              "roles/storage.objectAdmin",
              "roles/storage.objectViewer",
            ]
          ))
        )
      }
    }
  }
}
# tftest modules=1 resources=2 inventory=iam-bindings.yaml
```

```hcl
module "bucket" {
  source     = "./fabric/modules/gcs"
  project_id = "myproject"
  name       = "my-bucket"
  iam_bindings_additive = {
    storage-admin-with-delegated_roles = {
      role   = "roles/storage.admin"
      member = "group:storage@example.com"
      condition = {
        title = "delegated-role-grants"
        expression = format(
          "api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly([%s])",
          join(",", formatlist("'%s'",
            [
              "roles/storage.objectAdmin",
              "roles/storage.objectViewer",
            ]
          ))
        )
      }
    }
  }
}
# tftest modules=1 resources=2 inventory=iam-bindings-additive.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L164) | Bucket name suffix. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L219) | Bucket project id. | <code>string</code> | ✓ |  |
| [autoclass](variables.tf#L17) | Enable autoclass to automatically transition objects to appropriate storage classes based on their access pattern. If set to true, storage_class must be set to STANDARD. Defaults to false. | <code>bool</code> |  | <code>false</code> |
| [cors](variables.tf#L23) | CORS configuration for the bucket. Defaults to null. | <code title="object&#40;&#123;&#10;  origin          &#61; optional&#40;list&#40;string&#41;&#41;&#10;  method          &#61; optional&#40;list&#40;string&#41;&#41;&#10;  response_header &#61; optional&#40;list&#40;string&#41;&#41;&#10;  max_age_seconds &#61; optional&#40;number&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [custom_placement_config](variables.tf#L34) | The bucket's custom location configuration, which specifies the individual regions that comprise a dual-region bucket. If the bucket is designated as REGIONAL or MULTI_REGIONAL, the parameters are empty. | <code>list&#40;string&#41;</code> |  | <code>null</code> |
| [default_event_based_hold](variables.tf#L40) | Enable event based hold to new objects added to specific bucket, defaults to false. | <code>bool</code> |  | <code>null</code> |
| [encryption_key](variables.tf#L46) | KMS key that will be used for encryption. | <code>string</code> |  | <code>null</code> |
| [force_destroy](variables.tf#L52) | Optional map to set force destroy keyed by name, defaults to false. | <code>bool</code> |  | <code>false</code> |
| [iam](variables.tf#L58) | IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings](variables.tf#L64) | Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  members &#61; list&#40;string&#41;&#10;  role    &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings_additive](variables.tf#L79) | Individual additive IAM bindings. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  member &#61; string&#10;  role   &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [labels](variables.tf#L94) | Labels to be attached to all buckets. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [lifecycle_rules](variables.tf#L100) | Bucket lifecycle rule. | <code title="map&#40;object&#40;&#123;&#10;  action &#61; object&#40;&#123;&#10;    type          &#61; string&#10;    storage_class &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#10;  condition &#61; object&#40;&#123;&#10;    age                        &#61; optional&#40;number&#41;&#10;    created_before             &#61; optional&#40;string&#41;&#10;    custom_time_before         &#61; optional&#40;string&#41;&#10;    days_since_custom_time     &#61; optional&#40;number&#41;&#10;    days_since_noncurrent_time &#61; optional&#40;number&#41;&#10;    matches_prefix             &#61; optional&#40;list&#40;string&#41;&#41;&#10;    matches_storage_class      &#61; optional&#40;list&#40;string&#41;&#41; &#35; STANDARD, MULTI_REGIONAL, REGIONAL, NEARLINE, COLDLINE, ARCHIVE, DURABLE_REDUCED_AVAILABILITY&#10;    matches_suffix             &#61; optional&#40;list&#40;string&#41;&#41;&#10;    noncurrent_time_before     &#61; optional&#40;string&#41;&#10;    num_newer_versions         &#61; optional&#40;number&#41;&#10;    with_state                 &#61; optional&#40;string&#41; &#35; &#34;LIVE&#34;, &#34;ARCHIVED&#34;, &#34;ANY&#34;&#10;  &#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [location](variables.tf#L149) | Bucket location. | <code>string</code> |  | <code>&#34;EU&#34;</code> |
| [logging_config](variables.tf#L155) | Bucket logging configuration. | <code title="object&#40;&#123;&#10;  log_bucket        &#61; string&#10;  log_object_prefix &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [notification_config](variables.tf#L169) | GCS Notification configuration. | <code title="object&#40;&#123;&#10;  enabled            &#61; bool&#10;  payload_format     &#61; string&#10;  topic_name         &#61; string&#10;  sa_email           &#61; string&#10;  event_types        &#61; optional&#40;list&#40;string&#41;&#41;&#10;  custom_attributes  &#61; optional&#40;map&#40;string&#41;&#41;&#10;  object_name_prefix &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [objects_to_upload](variables.tf#L183) | Objects to be uploaded to bucket. | <code title="map&#40;object&#40;&#123;&#10;  name                &#61; string&#10;  metadata            &#61; optional&#40;map&#40;string&#41;&#41;&#10;  content             &#61; optional&#40;string&#41;&#10;  source              &#61; optional&#40;string&#41;&#10;  cache_control       &#61; optional&#40;string&#41;&#10;  content_disposition &#61; optional&#40;string&#41;&#10;  content_encoding    &#61; optional&#40;string&#41;&#10;  content_language    &#61; optional&#40;string&#41;&#10;  content_type        &#61; optional&#40;string&#41;&#10;  event_based_hold    &#61; optional&#40;bool&#41;&#10;  temporary_hold      &#61; optional&#40;bool&#41;&#10;  detect_md5hash      &#61; optional&#40;string&#41;&#10;  storage_class       &#61; optional&#40;string&#41;&#10;  kms_key_name        &#61; optional&#40;string&#41;&#10;  customer_encryption &#61; optional&#40;object&#40;&#123;&#10;    encryption_algorithm &#61; optional&#40;string&#41;&#10;    encryption_key       &#61; string&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [prefix](variables.tf#L209) | Optional prefix used to generate the bucket name. | <code>string</code> |  | <code>null</code> |
| [requester_pays](variables.tf#L224) | Enables Requester Pays on a storage bucket. | <code>bool</code> |  | <code>null</code> |
| [retention_policy](variables.tf#L230) | Bucket retention policy. | <code title="object&#40;&#123;&#10;  retention_period &#61; number&#10;  is_locked        &#61; optional&#40;bool&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [storage_class](variables.tf#L239) | Bucket storage class. | <code>string</code> |  | <code>&#34;MULTI_REGIONAL&#34;</code> |
| [uniform_bucket_level_access](variables.tf#L249) | Allow using object ACLs (false) or not (true, this is the recommended behavior) , defaults to true (which is the recommended practice, but not the behavior of storage API). | <code>bool</code> |  | <code>true</code> |
| [versioning](variables.tf#L255) | Enable versioning, defaults to false. | <code>bool</code> |  | <code>false</code> |
| [website](variables.tf#L261) | Bucket website. | <code title="object&#40;&#123;&#10;  main_page_suffix &#61; optional&#40;string&#41;&#10;  not_found_page   &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [bucket](outputs.tf#L17) | Bucket resource. |  |
| [id](outputs.tf#L28) | Fully qualified bucket id. |  |
| [name](outputs.tf#L37) | Bucket name. |  |
| [notification](outputs.tf#L46) | GCS Notification self link. |  |
| [objects](outputs.tf#L51) | Objects in GCS bucket. |  |
| [topic](outputs.tf#L63) | Topic ID used by GCS. |  |
| [url](outputs.tf#L68) | Bucket URL. |  |
<!-- END TFDOC -->
