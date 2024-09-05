# Google Cloud Storage Module

<!-- BEGIN TOC -->
- [Simple bucket example](#simple-bucket-example)
- [Cloud KMS](#cloud-kms)
- [Retention policy, soft delete policy and logging](#retention-policy-soft-delete-policy-and-logging)
- [Lifecycle rule](#lifecycle-rule)
- [GCS notifications](#gcs-notifications)
- [Object upload](#object-upload)
- [IAM](#iam)
- [Tag Bindings](#tag-bindings)
- [Managed Folders](#managed-folders)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Simple bucket example

```hcl
module "bucket" {
  source     = "./fabric/modules/gcs"
  project_id = var.project_id
  prefix     = var.prefix
  name       = "my-bucket"
  location   = "EU"
  versioning = true
  labels = {
    cost-center = "devops"
  }
}
# tftest modules=1 resources=1 inventory=simple.yaml e2e
```

## Cloud KMS

```hcl
module "project" {
  source         = "./fabric/modules/project"
  name           = var.project_id
  project_create = false
  services       = ["storage.googleapis.com"]
}

module "kms" {
  source     = "./fabric/modules/kms"
  project_id = var.project_id
  keyring = {
    location = "europe" # location of the KMS must match location of the bucket
    name     = "test"
  }
  keys = {
    bucket_key = {
      iam_bindings = {
        bucket_key_iam = {
          members = [module.project.service_agents.storage.iam_email]
          role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
        }
      }
    }
  }
}

module "bucket" {
  source         = "./fabric/modules/gcs"
  project_id     = var.project_id
  prefix         = var.prefix
  name           = "my-bucket"
  location       = "EU"
  encryption_key = module.kms.keys.bucket_key.id
}

# tftest modules=3 skip e2e
```

## Retention policy, soft delete policy and logging

```hcl
module "bucket" {
  source     = "./fabric/modules/gcs"
  project_id = var.project_id
  prefix     = var.prefix
  name       = "my-bucket"
  location   = "EU"
  retention_policy = {
    retention_period = 100
    is_locked        = true
  }
  soft_delete_retention = 7776000
  logging_config = {
    log_bucket        = "log-bucket"
    log_object_prefix = null
  }
}
# tftest modules=1 resources=1 inventory=retention-logging.yaml
```

## Lifecycle rule

```hcl
module "bucket" {
  source     = "./fabric/modules/gcs"
  project_id = var.project_id
  prefix     = var.prefix
  name       = "my-bucket"
  location   = "EU"
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
# tftest modules=1 resources=1 inventory=lifecycle.yaml e2e
```

## GCS notifications

```hcl
module "project" {
  source         = "./fabric/modules/project"
  name           = var.project_id
  project_create = false
  services       = ["storage.googleapis.com"]
}

module "bucket-gcs-notification" {
  source     = "./fabric/modules/gcs"
  project_id = var.project_id
  prefix     = var.prefix
  name       = "my-bucket"
  location   = "EU"
  notification_config = {
    enabled           = true
    payload_format    = "JSON_API_V1"
    sa_email          = module.project.service_agents.storage.email
    topic_name        = "gcs-notification-topic"
    event_types       = ["OBJECT_FINALIZE"]
    custom_attributes = {}
  }
}
# tftest skip e2e
```

## Object upload

```hcl
module "bucket" {
  source     = "./fabric/modules/gcs"
  project_id = var.project_id
  prefix     = var.prefix
  name       = "my-bucket"
  location   = "EU"
  objects_to_upload = {
    sample-data = {
      name         = "example-file.csv"
      source       = "assets/example-file.csv"
      content_type = "text/csv"
    }
  }
}
# tftest modules=1 resources=2 inventory=object-upload.yaml e2e
```

## IAM

IAM is managed via several variables that implement different features and levels of control:

- `iam` and `iam_by_principals` configure authoritative bindings that manage individual roles exclusively, and are internally merged
- `iam_bindings` configure authoritative bindings with optional support for conditions, and are not internally merged with the previous two variables
- `iam_bindings_additive` configure additive bindings via individual role/member pairs with optional support  conditions

The authoritative and additive approaches can be used together, provided different roles are managed by each. Some care must also be taken with the `iam_by_principals` variable to ensure that variable keys are static values, so that Terraform is able to compute the dependency graph.

Refer to the [project module](../project/README.md#iam) for examples of the IAM interface.

```hcl
module "bucket" {
  source     = "./fabric/modules/gcs"
  project_id = var.project_id
  prefix     = var.prefix
  name       = "my-bucket"
  location   = "EU"
  iam = {
    "roles/storage.admin" = ["group:${var.group_email}"]
  }
}
# tftest modules=1 resources=2 inventory=iam-authoritative.yaml e2e
```

```hcl
module "bucket" {
  source     = "./fabric/modules/gcs"
  project_id = var.project_id
  prefix     = var.prefix
  name       = "my-bucket"
  location   = "EU"
  iam_bindings = {
    storage-admin-with-delegated_roles = {
      role    = "roles/storage.admin"
      members = ["group:${var.group_email}"]
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
# tftest modules=1 resources=2 inventory=iam-bindings.yaml e2e
```

```hcl
module "bucket" {
  source     = "./fabric/modules/gcs"
  project_id = var.project_id
  prefix     = var.prefix
  name       = "my-bucket"
  location   = "EU"
  iam_bindings_additive = {
    storage-admin-with-delegated_roles = {
      role   = "roles/storage.admin"
      member = "group:${var.group_email}"
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
# tftest modules=1 resources=2 inventory=iam-bindings-additive.yaml e2e
```

## Tag Bindings

Refer to the [Creating and managing tags](https://cloud.google.com/resource-manager/docs/tags/tags-creating-and-managing) documentation for details on usage.

```hcl
module "org" {
  source          = "./fabric/modules/organization"
  organization_id = var.organization_id
  tags = {
    environment = {
      description = "Environment specification."
      values = {
        dev     = {}
        prod    = {}
        sandbox = {}
      }
    }
  }
}

module "bucket" {
  source     = "./fabric/modules/gcs"
  project_id = var.project_id
  prefix     = var.prefix
  name       = "my-bucket"
  location   = "EU"
  tag_bindings = {
    env-sandbox = module.org.tag_values["environment/sandbox"].id
  }
}
# tftest modules=2 resources=6
```

## Managed Folders
```hcl
module "bucket" {
  source     = "./fabric/modules/gcs"
  project_id = var.project_id
  prefix     = var.prefix
  name       = "my-bucket"
  location   = "EU"
  managed_folders = {
    folder1 = {
      iam = {
        "roles/storage.admin" = ["user:user1@example.com"]
      }
    }
    "folder1/subfolder" = {
      force_destroy = true
    }
  }
}
# tftest inventory=managed-folders.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [location](variables.tf#L156) | Bucket location. | <code>string</code> | ✓ |  |
| [name](variables.tf#L199) | Bucket name suffix. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L255) | Bucket project id. | <code>string</code> | ✓ |  |
| [autoclass](variables.tf#L17) | Enable autoclass to automatically transition objects to appropriate storage classes based on their access pattern. If set to true, storage_class must be set to STANDARD. Defaults to false. | <code>bool</code> |  | <code>null</code> |
| [cors](variables.tf#L23) | CORS configuration for the bucket. Defaults to null. | <code title="object&#40;&#123;&#10;  origin          &#61; optional&#40;list&#40;string&#41;&#41;&#10;  method          &#61; optional&#40;list&#40;string&#41;&#41;&#10;  response_header &#61; optional&#40;list&#40;string&#41;&#41;&#10;  max_age_seconds &#61; optional&#40;number&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [custom_placement_config](variables.tf#L34) | The bucket's custom location configuration, which specifies the individual regions that comprise a dual-region bucket. If the bucket is designated as REGIONAL or MULTI_REGIONAL, the parameters are empty. | <code>list&#40;string&#41;</code> |  | <code>null</code> |
| [default_event_based_hold](variables.tf#L40) | Enable event based hold to new objects added to specific bucket, defaults to false. | <code>bool</code> |  | <code>null</code> |
| [encryption_key](variables.tf#L46) | KMS key that will be used for encryption. | <code>string</code> |  | <code>null</code> |
| [force_destroy](variables.tf#L52) | Optional map to set force destroy keyed by name, defaults to false. | <code>bool</code> |  | <code>false</code> |
| [iam](variables.tf#L58) | IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings](variables.tf#L64) | Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  members &#61; list&#40;string&#41;&#10;  role    &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings_additive](variables.tf#L79) | Individual additive IAM bindings. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  member &#61; string&#10;  role   &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_by_principals](variables.tf#L94) | Authoritative IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid cycle errors. Merged internally with the `iam` variable. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [labels](variables.tf#L101) | Labels to be attached to all buckets. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [lifecycle_rules](variables.tf#L107) | Bucket lifecycle rule. | <code title="map&#40;object&#40;&#123;&#10;  action &#61; object&#40;&#123;&#10;    type          &#61; string&#10;    storage_class &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#10;  condition &#61; object&#40;&#123;&#10;    age                        &#61; optional&#40;number&#41;&#10;    created_before             &#61; optional&#40;string&#41;&#10;    custom_time_before         &#61; optional&#40;string&#41;&#10;    days_since_custom_time     &#61; optional&#40;number&#41;&#10;    days_since_noncurrent_time &#61; optional&#40;number&#41;&#10;    matches_prefix             &#61; optional&#40;list&#40;string&#41;&#41;&#10;    matches_storage_class      &#61; optional&#40;list&#40;string&#41;&#41; &#35; STANDARD, MULTI_REGIONAL, REGIONAL, NEARLINE, COLDLINE, ARCHIVE, DURABLE_REDUCED_AVAILABILITY&#10;    matches_suffix             &#61; optional&#40;list&#40;string&#41;&#41;&#10;    noncurrent_time_before     &#61; optional&#40;string&#41;&#10;    num_newer_versions         &#61; optional&#40;number&#41;&#10;    with_state                 &#61; optional&#40;string&#41; &#35; &#34;LIVE&#34;, &#34;ARCHIVED&#34;, &#34;ANY&#34;&#10;  &#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [logging_config](variables.tf#L162) | Bucket logging configuration. | <code title="object&#40;&#123;&#10;  log_bucket        &#61; string&#10;  log_object_prefix &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [managed_folders](variables.tf#L171) | Managed folders to create within the bucket in {PATH => CONFIG} format. | <code title="map&#40;object&#40;&#123;&#10;  force_destroy &#61; optional&#40;bool, false&#41;&#10;  iam           &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;    members &#61; list&#40;string&#41;&#10;    role    &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;    member &#61; string&#10;    role   &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [notification_config](variables.tf#L204) | GCS Notification configuration. | <code title="object&#40;&#123;&#10;  enabled            &#61; bool&#10;  payload_format     &#61; string&#10;  topic_name         &#61; string&#10;  sa_email           &#61; string&#10;  create_topic       &#61; optional&#40;bool, true&#41;&#10;  event_types        &#61; optional&#40;list&#40;string&#41;&#41;&#10;  custom_attributes  &#61; optional&#40;map&#40;string&#41;&#41;&#10;  object_name_prefix &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [objects_to_upload](variables.tf#L219) | Objects to be uploaded to bucket. | <code title="map&#40;object&#40;&#123;&#10;  name                &#61; string&#10;  metadata            &#61; optional&#40;map&#40;string&#41;&#41;&#10;  content             &#61; optional&#40;string&#41;&#10;  source              &#61; optional&#40;string&#41;&#10;  cache_control       &#61; optional&#40;string&#41;&#10;  content_disposition &#61; optional&#40;string&#41;&#10;  content_encoding    &#61; optional&#40;string&#41;&#10;  content_language    &#61; optional&#40;string&#41;&#10;  content_type        &#61; optional&#40;string&#41;&#10;  event_based_hold    &#61; optional&#40;bool&#41;&#10;  temporary_hold      &#61; optional&#40;bool&#41;&#10;  detect_md5hash      &#61; optional&#40;string&#41;&#10;  storage_class       &#61; optional&#40;string&#41;&#10;  kms_key_name        &#61; optional&#40;string&#41;&#10;  customer_encryption &#61; optional&#40;object&#40;&#123;&#10;    encryption_algorithm &#61; optional&#40;string&#41;&#10;    encryption_key       &#61; string&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [prefix](variables.tf#L245) | Optional prefix used to generate the bucket name. | <code>string</code> |  | <code>null</code> |
| [public_access_prevention](variables.tf#L260) | Prevents public access to the bucket. | <code>string</code> |  | <code>null</code> |
| [requester_pays](variables.tf#L270) | Enables Requester Pays on a storage bucket. | <code>bool</code> |  | <code>null</code> |
| [retention_policy](variables.tf#L276) | Bucket retention policy. | <code title="object&#40;&#123;&#10;  retention_period &#61; number&#10;  is_locked        &#61; optional&#40;bool&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [rpo](variables.tf#L285) | Bucket recovery point objective. | <code>string</code> |  | <code>null</code> |
| [soft_delete_retention](variables.tf#L295) | The duration in seconds that soft-deleted objects in the bucket will be retained and cannot be permanently deleted. Set to 0 to override the default and disable. | <code>number</code> |  | <code>null</code> |
| [storage_class](variables.tf#L301) | Bucket storage class. | <code>string</code> |  | <code>&#34;STANDARD&#34;</code> |
| [tag_bindings](variables.tf#L311) | Tag bindings for this folder, in key => tag value id format. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [uniform_bucket_level_access](variables.tf#L318) | Allow using object ACLs (false) or not (true, this is the recommended behavior) , defaults to true (which is the recommended practice, but not the behavior of storage API). | <code>bool</code> |  | <code>true</code> |
| [versioning](variables.tf#L324) | Enable versioning, defaults to false. | <code>bool</code> |  | <code>null</code> |
| [website](variables.tf#L330) | Bucket website. | <code title="object&#40;&#123;&#10;  main_page_suffix &#61; optional&#40;string&#41;&#10;  not_found_page   &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [bucket](outputs.tf#L17) | Bucket resource. |  |
| [id](outputs.tf#L28) | Fully qualified bucket id. |  |
| [name](outputs.tf#L39) | Bucket name. |  |
| [notification](outputs.tf#L50) | GCS Notification self link. |  |
| [objects](outputs.tf#L55) | Objects in GCS bucket. |  |
| [topic](outputs.tf#L67) | Topic ID used by GCS. |  |
| [url](outputs.tf#L72) | Bucket URL. |  |
<!-- END TFDOC -->
