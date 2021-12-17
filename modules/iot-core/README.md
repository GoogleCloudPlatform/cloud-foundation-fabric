# Google Cloud IoT Core Module

This module allows setting up Cloud IoT Core Registry, register devices and configure Pub/Sub topics.

Requires enabling the following APIs:
 "pubsub.googleapis.com",
 "cloudiot.googleapis.com"

## Example

```

provider "google" {
  project = "my-project"
  region = "my-region"
}

resource "google_pubsub_topic" "default-devicestatus" {
  name = "default-devicestatus"
}

resource "google_pubsub_topic" "default-telemetry" {
  name = "default-telemetry"
}

resource "google_pubsub_topic" "temp-telemetry" {
  name = "temp-telemetry"
}

resource "google_pubsub_topic" "hum-telemetry" {
  name = "hum-telemetry"
}

module "iot-platform" {
  source     = "./iot-core"
  telemetry_pub_sub_topic_id = google_pubsub_topic.default-telemetry.id
  status_pub_sub_topic_id = google_pubsub_topic.default-devicestatus.id
  extra_telemetry_pub_sub_topic_ids = [{
      "mqtt_topic" = "humidity"
      "pub_sub_topic" =  google_pubsub_topic.hum-telemetry.id
  },
  {
      "mqtt_topic" = "temperature"
      "pub_sub_topic" =  google_pubsub_topic.temp-telemetry.id
  }]
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
| extra_telemetry_pub_sub_topic_ids | additional pub sub topics for telemetry messages in adhoc MQTT topics (Device-->GCP) in the format MQTT_TOPIC:PUB_SUB_TOPIC_ID | <code title="list&#40;object&#40;&#123;&#10;mqtt_topic &#61; string&#10;pub_sub_topic &#61; string&#10;&#125;&#41;&#41;">list(object({...}))</code> | ✓ |  |
| status_pub_sub_topic_id | pub sub topic for status messages (GCP-->Device) | <code title="">string</code> | ✓ |  |
| telemetry_pub_sub_topic_id | pub sub topic for telemetry messages (Device-->GCP) | <code title="">string</code> | ✓ |  |
| *devices* | Devices map to be registered in the IoT Registry in the form DEVICE_ID: DEVICE_CERTIFICATE | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| iot_registry | Cloud IoT Core Registry |  |
<!-- END TFDOC -->

