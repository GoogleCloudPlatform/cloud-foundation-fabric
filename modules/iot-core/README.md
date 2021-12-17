# Google Cloud IoT Core Module

This module allows setting up Cloud IoT Core Registry, register devices and configure Pub/Sub topics.

Requires enabling the following APIs:
 "pubsub.googleapis.com",
 "cloudiot.googleapis.com"

## Example

```
module "iot-platform" {
  source     = "./iot-core"
  project_id = "my-project"
  region = "my-region"
  devices = {
      device_1 = "device_certs/rsa_cert1.pem"
      device_2 = "device_certs/rsa_cert2.pem"
  }
}
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

