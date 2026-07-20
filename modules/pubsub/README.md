# Google Cloud Pub/Sub Module

This module allows managing a single Pub/Sub topic, including multiple subscriptions and IAM bindings at the topic and subscriptions levels, as well as schemas.

<!-- BEGIN TOC -->
- [Simple topic with IAM](#simple-topic-with-iam)
- [Topic with schema](#topic-with-schema)
- [Subscriptions](#subscriptions)
- [Push subscriptions](#push-subscriptions)
- [BigQuery subscriptions](#bigquery-subscriptions)
- [BigQuery Subscription with service account email](#bigquery-subscription-with-service-account-email)
- [Cloud Storage subscriptions](#cloud-storage-subscriptions)
- [Subscriptions with IAM](#subscriptions-with-iam)
- [Variables](#variables)
- [Outputs](#outputs)
- [Fixtures](#fixtures)
<!-- END TOC -->

## Simple topic with IAM

IAM is managed via several variables that implement different features and levels of control:

- `iam` and `iam_by_principals` configure authoritative bindings that manage individual roles exclusively, and are internally merged
- `iam_bindings` configure authoritative bindings with optional support for conditions, and are not internally merged with the previous two variables
- `iam_bindings_additive` configure additive bindings via individual role/member pairs with optional support  conditions

The authoritative and additive approaches can be used together, provided different roles are managed by each. Some care must also be taken with the `iam_by_principals` variable to ensure that variable keys are static values, so that Terraform is able to compute the dependency graph.

Refer to the [project module](../project/README.md#iam) for examples of the IAM interface. IAM also supports variable interpolation for both roles and principals and for the foreign resources where the service account is the principal, via the respective attributes in the `var.context` variable. Basic usage is shown in the example below.

```hcl
module "pubsub" {
  source     = "./fabric/modules/pubsub"
  project_id = var.project_id
  name       = "my-topic"
  context = {
    iam_principals = {
      mygroup = "group:${var.group_email}"
    }
  }
  iam = {
    "roles/pubsub.viewer"     = ["$iam_principals:mygroup"]
    "roles/pubsub.subscriber" = ["serviceAccount:${var.service_account.email}"]
  }
}
# tftest modules=1 resources=3 inventory=simple.yaml e2e
```

## Topic with schema

```hcl
module "topic_with_schema" {
  source     = "./fabric/modules/pubsub"
  project_id = var.project_id
  name       = "my-topic"
  schema = {
    msg_encoding = "JSON"
    schema_type  = "AVRO"
    definition = jsonencode({
      "type" = "record",
      "name" = "Avro",
      "fields" = [{
        "name" = "StringField",
        "type" = "string"
        },
        {
          "name" = "FloatField",
          "type" = "float"
        },
        {
          "name" = "BooleanField",
          "type" = "boolean"
        },
      ]
    })
  }
}
# tftest modules=1 resources=2 inventory=schema.yaml e2e
```

## Subscriptions

Subscriptions are defined with the `subscriptions` variable, allowing optional configuration of per-subscription defaults. Push subscriptions need extra configuration, shown in the following example.

```hcl
module "pubsub" {
  source     = "./fabric/modules/pubsub"
  project_id = var.project_id
  name       = "my-topic"
  labels     = { test = "default" }
  subscriptions = {
    test-pull = {}
    test-pull-override = {
      labels                = { test = "override" }
      retain_acked_messages = true
    }
  }
}
# tftest modules=1 resources=3 inventory=subscriptions.yaml e2e
```

## Push subscriptions

Push subscriptions need extra configuration in the `push_configs` variable.

```hcl
module "pubsub" {
  source     = "./fabric/modules/pubsub"
  project_id = var.project_id
  name       = "my-topic"
  subscriptions = {
    test-push = {
      push = {
        endpoint = "https://example.com/foo"
      }
    }
  }
}
# tftest modules=1 resources=2 inventory=push-subscription.yaml e2e
```

## BigQuery subscriptions

BigQuery subscriptions need extra configuration in the `bigquery_subscription_configs` variable.

```hcl
module "pubsub" {
  source     = "./fabric/modules/pubsub"
  project_id = var.project_id
  name       = "my-topic"
  subscriptions = {
    test-bigquery = {
      bigquery = {
        table               = "${module.bigquery-dataset.tables["my_table"].project}:${module.bigquery-dataset.tables["my_table"].dataset_id}.${module.bigquery-dataset.tables["my_table"].table_id}"
        use_topic_schema    = true
        write_metadata      = false
        drop_unknown_fields = true
      }
    }
  }
}
# tftest modules=2 resources=5 fixtures=fixtures/bigquery-dataset.tf inventory=bigquery-subscription.yaml e2e
```

## BigQuery Subscription with service account email

BigQuery subscription example configuration with service account email.

```hcl
module "iam-service-account" {
  source     = "./fabric/modules/iam-service-account"
  project_id = var.project_id
  name       = "fixture-service-account"
  iam_project_roles = {
    "${var.project_id}" = [
      "roles/bigquery.dataEditor",
    ]
  }
}

module "pubsub" {
  source     = "./fabric/modules/pubsub"
  project_id = var.project_id
  name       = "my-topic"
  subscriptions = {
    test-bigquery-with-service-account = {
      bigquery = {
        table                 = "${module.bigquery-dataset.tables["my_table"].project}:${module.bigquery-dataset.tables["my_table"].dataset_id}.${module.bigquery-dataset.tables["my_table"].table_id}"
        use_table_schema      = true
        write_metadata        = false
        service_account_email = module.iam-service-account.email
      }
    }
  }
  depends_on = [
    module.iam-service-account # wait for IAM grants to finish
  ]
}
# tftest fixtures=fixtures/bigquery-dataset.tf inventory=bigquery-subscription-with-service-account.yaml e2e
```

## Cloud Storage subscriptions

Cloud Storage subscriptions need extra configuration in the `cloud_storage_subscription_configs` variable.

```hcl
module "pubsub" {
  source     = "./fabric/modules/pubsub"
  project_id = var.project_id
  name       = "my-topic"
  subscriptions = {
    test-cloudstorage = {
      cloud_storage = {
        bucket          = module.gcs.name
        filename_prefix = var.prefix
        filename_suffix = "test_suffix"
        max_duration    = "100s"
        max_bytes       = 1000
        avro_config = {
          write_metadata = true
        }
      }
    }
  }
}
# tftest modules=2 resources=4 fixtures=fixtures/gcs.tf inventory=cloud-storage-subscription.yaml e2e
```

## Subscriptions with IAM

```hcl
module "pubsub" {
  source     = "./fabric/modules/pubsub"
  project_id = var.project_id
  name       = "my-topic"
  subscriptions = {
    test-1 = {
      iam = {
        "roles/pubsub.subscriber" = ["serviceAccount:${var.service_account.email}"]
      }
    }
  }
}
# tftest modules=1 resources=3 inventory=subscription-iam.yaml e2e
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L55) | PubSub topic name. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L60) | Project used for resources. | <code>string</code> | ✓ |  |
| [context](variables.tf#L17) | Context-specific interpolations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam](variables-iam.tf#L17) | IAM bindings for topic in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings](variables-iam.tf#L24) | Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings_additive](variables-iam.tf#L39) | Keyring individual additive IAM bindings. Keys are arbitrary. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_by_principals](variables-iam.tf#L54) | Authoritative IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid cycle errors. Merged internally with the `iam` variable. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [kms_key](variables.tf#L30) | KMS customer managed encryption key. | <code>string</code> |  | <code>null</code> |
| [labels](variables.tf#L36) | Labels. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [message_retention_duration](variables.tf#L43) | Minimum duration to retain a message after it is published to the topic. | <code>string</code> |  | <code>null</code> |
| [message_storage_enforce_in_transit](variables.tf#L49) | If true, var.regions is also used to enforce in-transit guarantees for messages. | <code>bool</code> |  | <code>null</code> |
| [regions](variables.tf#L65) | List of regions used to set persistence policy. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [schema](variables.tf#L72) | Topic schema. If set, all messages in this topic should follow this schema. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [subscriptions](variables.tf#L82) | Topic subscriptions. Also define push configs for push subscriptions. If options is set to null subscription defaults will be used. Labels default to topic labels if set to null. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L17) | Fully qualified topic id. |  |
| [schema](outputs.tf#L28) | Schema resource. |  |
| [schema_id](outputs.tf#L33) | Schema resource id. |  |
| [subscription_id](outputs.tf#L38) | Subscription ids. |  |
| [subscriptions](outputs.tf#L50) | Subscription resources. |  |
| [topic](outputs.tf#L60) | Topic resource. |  |

## Fixtures

- [bigquery-dataset.tf](../../tests/fixtures/bigquery-dataset.tf)
- [gcs.tf](../../tests/fixtures/gcs.tf)
<!-- END TFDOC -->
