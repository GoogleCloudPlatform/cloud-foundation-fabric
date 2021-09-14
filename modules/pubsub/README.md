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
# tftest:modules=1:resources=3
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
# tftest:modules=1:resources=3
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
# tftest:modules=1:resources=2
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
# tftest:modules=1:resources=3
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| name | PubSub topic name. | <code title="">string</code> | ✓ |  |
| project_id | Project used for resources. | <code title="">string</code> | ✓ |  |
| *dead_letter_configs* | Per-subscription dead letter policy configuration. | <code title="map&#40;object&#40;&#123;&#10;topic                 &#61; string&#10;max_delivery_attempts &#61; number&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |
| *defaults* | Subscription defaults for options. | <code title="object&#40;&#123;&#10;ack_deadline_seconds       &#61; number&#10;message_retention_duration &#61; string&#10;retain_acked_messages      &#61; bool&#10;expiration_policy_ttl      &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;ack_deadline_seconds       &#61; null&#10;message_retention_duration &#61; null&#10;retain_acked_messages      &#61; null&#10;expiration_policy_ttl      &#61; null&#10;&#125;">...</code> |
| *iam* | IAM bindings for topic in {ROLE => [MEMBERS]} format. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *kms_key* | KMS customer managed encryption key. | <code title="">string</code> |  | <code title="">null</code> |
| *labels* | Labels. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *push_configs* | Push subscription configurations. | <code title="map&#40;object&#40;&#123;&#10;attributes &#61; map&#40;string&#41;&#10;endpoint   &#61; string&#10;oidc_token &#61; object&#40;&#123;&#10;audience              &#61; string&#10;service_account_email &#61; string&#10;&#125;&#41;&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |
| *regions* | List of regions used to set persistence policy. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *subscription_iam* | IAM bindings for subscriptions in {SUBSCRIPTION => {ROLE => [MEMBERS]}} format. | <code title="map&#40;map&#40;list&#40;string&#41;&#41;&#41;">map(map(list(string)))</code> |  | <code title="">{}</code> |
| *subscriptions* | Topic subscriptions. Also define push configs for push subscriptions. If options is set to null subscription defaults will be used. Labels default to topic labels if set to null. | <code title="map&#40;object&#40;&#123;&#10;labels &#61; map&#40;string&#41;&#10;options &#61; object&#40;&#123;&#10;ack_deadline_seconds       &#61; number&#10;message_retention_duration &#61; string&#10;retain_acked_messages      &#61; bool&#10;expiration_policy_ttl      &#61; string&#10;&#125;&#41;&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| id | Topic id. |  |
| subscription_id | Subscription ids. |  |
| subscriptions | Subscription resources. |  |
| topic | Topic resource. |  |
<!-- END TFDOC -->
