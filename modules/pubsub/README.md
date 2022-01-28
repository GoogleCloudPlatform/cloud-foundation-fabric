# Google Cloud Pub/Sub Module

This module allows managing a single Pub/Sub topic, including multiple subscriptions and IAM bindings at the topic and subscriptions levels.


## Examples

### Simple topic with IAM

```hcl
module "pubsub" {
  source     = "./modules/pubsub"
  project_id = "my-project"
  name       = "my-topic"
  iam = {
    "roles/pubsub.viewer"     = ["group:foo@example.com"]
    "roles/pubsub.subscriber" = ["user:user1@example.com"]
  }
}
# tftest modules=1 resources=3
```

### Subscriptions

Subscriptions are defined with the `subscriptions` variable, allowing optional configuration of per-subscription defaults. Push subscriptions need extra configuration, shown in the following example.

```hcl
module "pubsub" {
  source     = "./modules/pubsub"
  project_id = "my-project"
  name       = "my-topic"
  subscriptions = {
    test-pull = null
    test-pull-override = {
      labels = { test = "override" }
      options = {
        ack_deadline_seconds       = null
        message_retention_duration = null
        retain_acked_messages      = true
        expiration_policy_ttl      = null
      }
    }
  }
}
# tftest modules=1 resources=3
```

### Push subscriptions

Push subscriptions need extra configuration in the `push_configs` variable.

```hcl
module "pubsub" {
  source     = "./modules/pubsub"
  project_id = "my-project"
  name       = "my-topic"
  subscriptions = {
    test-push = null
  }
  push_configs = {
    test-push = {
      endpoint   = "https://example.com/foo"
      attributes = null
      oidc_token = null
    }
  }
}
# tftest modules=1 resources=2
```

### Subscriptions with IAM

```hcl
module "pubsub" {
  source     = "./modules/pubsub"
  project_id = "my-project"
  name       = "my-topic"
  subscriptions = {
    test-1 = null
    test-1 = null
  }
  subscription_iam = {
    test-1 = {
      "roles/pubsub.subscriber" = ["user:user1@ludomagno.net"]
    }
  }
}
# tftest modules=1 resources=3
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L60) | PubSub topic name. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L65) | Project used for resources. | <code>string</code> | ✓ |  |
| [dead_letter_configs](variables.tf#L17) | Per-subscription dead letter policy configuration. | <code title="map&#40;object&#40;&#123;&#10;  topic                 &#61; string&#10;  max_delivery_attempts &#61; number&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [defaults](variables.tf#L26) | Subscription defaults for options. | <code title="object&#40;&#123;&#10;  ack_deadline_seconds       &#61; number&#10;  message_retention_duration &#61; string&#10;  retain_acked_messages      &#61; bool&#10;  expiration_policy_ttl      &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  ack_deadline_seconds       &#61; null&#10;  message_retention_duration &#61; null&#10;  retain_acked_messages      &#61; null&#10;  expiration_policy_ttl      &#61; null&#10;&#125;">&#123;&#8230;&#125;</code> |
| [iam](variables.tf#L42) | IAM bindings for topic in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [kms_key](variables.tf#L48) | KMS customer managed encryption key. | <code>string</code> |  | <code>null</code> |
| [labels](variables.tf#L54) | Labels. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [push_configs](variables.tf#L70) | Push subscription configurations. | <code title="map&#40;object&#40;&#123;&#10;  attributes &#61; map&#40;string&#41;&#10;  endpoint   &#61; string&#10;  oidc_token &#61; object&#40;&#123;&#10;    audience              &#61; string&#10;    service_account_email &#61; string&#10;  &#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [regions](variables.tf#L83) | List of regions used to set persistence policy. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [subscription_iam](variables.tf#L89) | IAM bindings for subscriptions in {SUBSCRIPTION => {ROLE => [MEMBERS]}} format. | <code>map&#40;map&#40;list&#40;string&#41;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [subscriptions](variables.tf#L95) | Topic subscriptions. Also define push configs for push subscriptions. If options is set to null subscription defaults will be used. Labels default to topic labels if set to null. | <code title="map&#40;object&#40;&#123;&#10;  labels &#61; map&#40;string&#41;&#10;  options &#61; object&#40;&#123;&#10;    ack_deadline_seconds       &#61; number&#10;    message_retention_duration &#61; string&#10;    retain_acked_messages      &#61; bool&#10;    expiration_policy_ttl      &#61; string&#10;  &#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L17) | Topic id. |  |
| [subscription_id](outputs.tf#L25) | Subscription ids. |  |
| [subscriptions](outputs.tf#L35) | Subscription resources. |  |
| [topic](outputs.tf#L43) | Topic resource. |  |

<!-- END TFDOC -->
