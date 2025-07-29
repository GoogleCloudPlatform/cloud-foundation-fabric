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
| [name](variables.tf#L48) | PubSub topic name. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L53) | Project used for resources. | <code>string</code> | ✓ |  |
| [context](variables.tf#L17) | Context-specific interpolations. | <code title="object&#40;&#123;&#10;  custom_roles   &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  iam_principals &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  locations      &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  project_ids    &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam](variables-iam.tf#L17) | IAM bindings for topic in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings](variables-iam.tf#L24) | Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  members &#61; list&#40;string&#41;&#10;  role    &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings_additive](variables-iam.tf#L39) | Keyring individual additive IAM bindings. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  member &#61; string&#10;  role   &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_by_principals](variables-iam.tf#L54) | Authoritative IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid cycle errors. Merged internally with the `iam` variable. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [kms_key](variables.tf#L29) | KMS customer managed encryption key. | <code>string</code> |  | <code>null</code> |
| [labels](variables.tf#L35) | Labels. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [message_retention_duration](variables.tf#L42) | Minimum duration to retain a message after it is published to the topic. | <code>string</code> |  | <code>null</code> |
| [regions](variables.tf#L58) | List of regions used to set persistence policy. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [schema](variables.tf#L65) | Topic schema. If set, all messages in this topic should follow this schema. | <code title="object&#40;&#123;&#10;  definition   &#61; string&#10;  msg_encoding &#61; optional&#40;string, &#34;ENCODING_UNSPECIFIED&#34;&#41;&#10;  schema_type  &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [subscriptions](variables.tf#L75) | Topic subscriptions. Also define push configs for push subscriptions. If options is set to null subscription defaults will be used. Labels default to topic labels if set to null. | <code title="map&#40;object&#40;&#123;&#10;  ack_deadline_seconds         &#61; optional&#40;number&#41;&#10;  enable_exactly_once_delivery &#61; optional&#40;bool, false&#41;&#10;  enable_message_ordering      &#61; optional&#40;bool, false&#41;&#10;  expiration_policy_ttl        &#61; optional&#40;string&#41;&#10;  filter                       &#61; optional&#40;string&#41;&#10;  iam                          &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  labels                       &#61; optional&#40;map&#40;string&#41;&#41;&#10;  message_retention_duration   &#61; optional&#40;string&#41;&#10;  retain_acked_messages        &#61; optional&#40;bool, false&#41;&#10;  bigquery &#61; optional&#40;object&#40;&#123;&#10;    table                 &#61; string&#10;    drop_unknown_fields   &#61; optional&#40;bool, false&#41;&#10;    service_account_email &#61; optional&#40;string&#41;&#10;    use_table_schema      &#61; optional&#40;bool, false&#41;&#10;    use_topic_schema      &#61; optional&#40;bool, false&#41;&#10;    write_metadata        &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;&#41;&#10;  cloud_storage &#61; optional&#40;object&#40;&#123;&#10;    bucket          &#61; string&#10;    filename_prefix &#61; optional&#40;string&#41;&#10;    filename_suffix &#61; optional&#40;string&#41;&#10;    max_duration    &#61; optional&#40;string&#41;&#10;    max_bytes       &#61; optional&#40;number&#41;&#10;    avro_config &#61; optional&#40;object&#40;&#123;&#10;      write_metadata &#61; optional&#40;bool, false&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  dead_letter_policy &#61; optional&#40;object&#40;&#123;&#10;    topic                 &#61; string&#10;    max_delivery_attempts &#61; optional&#40;number&#41;&#10;  &#125;&#41;&#41;&#10;  iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;    members &#61; list&#40;string&#41;&#10;    role    &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;    member &#61; string&#10;    role   &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  push &#61; optional&#40;object&#40;&#123;&#10;    endpoint   &#61; string&#10;    attributes &#61; optional&#40;map&#40;string&#41;&#41;&#10;    no_wrapper &#61; optional&#40;object&#40;&#123;&#10;      write_metadata &#61; optional&#40;bool, false&#41;&#10;    &#125;&#41;&#41;&#10;    oidc_token &#61; optional&#40;object&#40;&#123;&#10;      audience              &#61; optional&#40;string&#41;&#10;      service_account_email &#61; string&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  retry_policy &#61; optional&#40;object&#40;&#123;&#10;    minimum_backoff &#61; optional&#40;number&#41;&#10;    maximum_backoff &#61; optional&#40;number&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

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
