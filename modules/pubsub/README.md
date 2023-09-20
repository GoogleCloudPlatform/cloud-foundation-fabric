# Google Cloud Pub/Sub Module

This module allows managing a single Pub/Sub topic, including multiple subscriptions and IAM bindings at the topic and subscriptions levels, as well as schemas.

## Examples

### Simple topic with IAM

```hcl
module "pubsub" {
  source     = "./fabric/modules/pubsub"
  project_id = "my-project"
  name       = "my-topic"
  iam = {
    "roles/pubsub.viewer"     = ["group:foo@example.com"]
    "roles/pubsub.subscriber" = ["user:user1@example.com"]
  }
}
# tftest modules=1 resources=3 inventory=simple.yaml
```

### Topic with schema

```hcl
module "topic_with_schema" {
  source     = "./fabric/modules/pubsub"
  project_id = "my-project"
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
# tftest modules=1 resources=2 inventory=schema.yaml
```

### Subscriptions

Subscriptions are defined with the `subscriptions` variable, allowing optional configuration of per-subscription defaults. Push subscriptions need extra configuration, shown in the following example.

```hcl
module "pubsub" {
  source     = "./fabric/modules/pubsub"
  project_id = "my-project"
  name       = "my-topic"
  subscriptions = {
    test-pull = {}
    test-pull-override = {
      labels                = { test = "override" }
      retain_acked_messages = true
    }
  }
}
# tftest modules=1 resources=3 inventory=subscriptions.yaml
```

### Push subscriptions

Push subscriptions need extra configuration in the `push_configs` variable.

```hcl
module "pubsub" {
  source     = "./fabric/modules/pubsub"
  project_id = "my-project"
  name       = "my-topic"
  subscriptions = {
    test-push = {
      push = {
        endpoint = "https://example.com/foo"
      }
    }
  }
}
# tftest modules=1 resources=2
```

### BigQuery subscriptions

BigQuery subscriptions need extra configuration in the `bigquery_subscription_configs` variable.

```hcl
module "pubsub" {
  source     = "./fabric/modules/pubsub"
  project_id = "my-project"
  name       = "my-topic"
  subscriptions = {
    test-bigquery = {
      bigquery = {
        table               = "my_project_id:my_dataset.my_table"
        use_topic_schema    = true
        write_metadata      = false
        drop_unknown_fields = true
      }
    }
  }
}
# tftest modules=1 resources=2
```

### Cloud Storage subscriptions

Cloud Storage subscriptions need extra configuration in the `cloud_storage_subscription_configs` variable.

```hcl
module "pubsub" {
  source     = "./fabric/modules/pubsub"
  project_id = "my-project"
  name       = "my-topic"
  subscriptions = {
    test-cloudstorage = {
      cloud_storage = {
        bucket          = "my-bucket"
        filename_prefix = "test_prefix"
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
# tftest modules=1 resources=2
```
### Subscriptions with IAM

```hcl
module "pubsub" {
  source     = "./fabric/modules/pubsub"
  project_id = "my-project"
  name       = "my-topic"
  subscriptions = {
    test-1 = {
      iam = {
        "roles/pubsub.subscriber" = ["user:user1@example.com"]
      }
    }
  }
}
# tftest modules=1 resources=3
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L73) | PubSub topic name. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L78) | Project used for resources. | <code>string</code> | ✓ |  |
| [iam](variables.tf#L17) | IAM bindings for topic in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings](variables.tf#L24) | Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  members &#61; list&#40;string&#41;&#10;  role    &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings_additive](variables.tf#L39) | Keyring individual additive IAM bindings. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  member &#61; string&#10;  role   &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [kms_key](variables.tf#L54) | KMS customer managed encryption key. | <code>string</code> |  | <code>null</code> |
| [labels](variables.tf#L60) | Labels. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [message_retention_duration](variables.tf#L67) | Minimum duration to retain a message after it is published to the topic. | <code>string</code> |  | <code>null</code> |
| [regions](variables.tf#L83) | List of regions used to set persistence policy. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [schema](variables.tf#L90) | Topic schema. If set, all messages in this topic should follow this schema. | <code title="object&#40;&#123;&#10;  definition   &#61; string&#10;  msg_encoding &#61; optional&#40;string, &#34;ENCODING_UNSPECIFIED&#34;&#41;&#10;  schema_type  &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [subscriptions](variables.tf#L100) | Topic subscriptions. Also define push configs for push subscriptions. If options is set to null subscription defaults will be used. Labels default to topic labels if set to null. | <code title="map&#40;object&#40;&#123;&#10;  labels                       &#61; optional&#40;map&#40;string&#41;&#41;&#10;  ack_deadline_seconds         &#61; optional&#40;number&#41;&#10;  message_retention_duration   &#61; optional&#40;string&#41;&#10;  retain_acked_messages        &#61; optional&#40;bool, false&#41;&#10;  expiration_policy_ttl        &#61; optional&#40;string&#41;&#10;  filter                       &#61; optional&#40;string&#41;&#10;  enable_message_ordering      &#61; optional&#40;bool, false&#41;&#10;  enable_exactly_once_delivery &#61; optional&#40;bool, false&#41;&#10;  dead_letter_policy &#61; optional&#40;object&#40;&#123;&#10;    topic                 &#61; string&#10;    max_delivery_attempts &#61; optional&#40;number&#41;&#10;  &#125;&#41;&#41;&#10;  retry_policy &#61; optional&#40;object&#40;&#123;&#10;    minimum_backoff &#61; optional&#40;number&#41;&#10;    maximum_backoff &#61; optional&#40;number&#41;&#10;  &#125;&#41;&#41;&#10;&#10;&#10;  bigquery &#61; optional&#40;object&#40;&#123;&#10;    table               &#61; string&#10;    use_topic_schema    &#61; optional&#40;bool, false&#41;&#10;    write_metadata      &#61; optional&#40;bool, false&#41;&#10;    drop_unknown_fields &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;&#41;&#10;  cloud_storage &#61; optional&#40;object&#40;&#123;&#10;    bucket          &#61; string&#10;    filename_prefix &#61; optional&#40;string&#41;&#10;    filename_suffix &#61; optional&#40;string&#41;&#10;    max_duration    &#61; optional&#40;string&#41;&#10;    max_bytes       &#61; optional&#40;number&#41;&#10;    avro_config &#61; optional&#40;object&#40;&#123;&#10;      write_metadata &#61; optional&#40;bool, false&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  push &#61; optional&#40;object&#40;&#123;&#10;    endpoint   &#61; string&#10;    attributes &#61; optional&#40;map&#40;string&#41;&#41;&#10;    no_wrapper &#61; optional&#40;bool, false&#41;&#10;    oidc_token &#61; optional&#40;object&#40;&#123;&#10;      audience              &#61; optional&#40;string&#41;&#10;      service_account_email &#61; string&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;&#10;&#10;  iam &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;    members &#61; list&#40;string&#41;&#10;    role    &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;    member &#61; string&#10;    role   &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L17) | Fully qualified topic id. |  |
| [schema](outputs.tf#L27) | Schema resource. |  |
| [schema_id](outputs.tf#L32) | Schema resource id. |  |
| [subscription_id](outputs.tf#L37) | Subscription ids. |  |
| [subscriptions](outputs.tf#L48) | Subscription resources. |  |
| [topic](outputs.tf#L57) | Topic resource. |  |
<!-- END TFDOC -->
