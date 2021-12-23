# Google Cloud IoT Core Module

This module allows setting up Cloud IoT Core Registry, register devices and configure Pub/Sub topics.

Requires enabling the following APIs:
 "pubsub.googleapis.com",
 "cloudiot.googleapis.com"

## Simple Example

Simple example showing how to create an IoT Platform (IoT Core), connected to a set of given Pub-Sub topics and provision devices.

Before executing, device certificates shall be created, for example using:

```
openssl req -x509 -newkey rsa:2048 -keyout rsa_private.pem -nodes -out rsa_cert.pem -subj "/CN=unused"
```

And then provision public certificate path in the devices yaml file following the convention device_id: device_cert


```hcl
module "iot-platform" {
  source     = "./iot-core"
  project_id = "my_project_id"
  region = "europe-west1"
  telemetry_pub_sub_topic_id = "telemetry_topic_id"
  status_pub_sub_topic_id = "status_topic_id"
  devices_yaml_file = "devices.yaml"
}
# tftest:modules=1:resources=2

```

Now, we can test sending telemetry messages from devices to our IoT Platform, for example using the MQTT demo client at https://github.com/googleapis/nodejs-iot/tree/main/samples/mqtt_example

## Example with specific PubSub topics for custom MQTT topics

If you need to match specific MQTT topics (eg, /temperature) into specific PubSub topics, you can use extra_telemetry_pub_sub_topic_ids for that, as in the following example:

```hcl
module "iot-platform" {
  source     = "./iot-core"
  project_id = "my_project_id"
  region = "europe-west1"
  telemetry_pub_sub_topic_id = "telemetry_topic_id"
  status_pub_sub_topic_id = "statu_topic_id"
  extra_telemetry_pub_sub_topic_ids = [{
      "mqtt_topic" = "humidity"
      "pub_sub_topic" =  "hum_topic_id"
  },
  {
      "mqtt_topic" = "temperature"
      "pub_sub_topic" =  "temp_topic_id"
  }]
  devices_yaml_file = "devices.yaml"
}
# tftest:modules=1:resources=2

```

## Example integrated with Data Foundation Platform
In this example, we will show how to extend **[Data Foundations Platform](../../data-solutions/data-platform-foundations/)** including IoT Platform as a new source of data. 

INCLUDE HERE DIAGRAM


1. First, we will setup Environment following instructions in **[Environment Setup](../../data-solutions/data-platform-foundations/01-environment/)** to setup projects and SAs required. Get output variable project_ids.landing as will be used later

1. Second, execute instructions in **[Environment Setup](../../data-solutions/data-platform-foundations/02-resources/)** to provision PubSub, DataFlow, BQ,... Get variable landing-pubsub as will be used later to create IoT Registry

1. Now it is time to provision IoT Platform. Modify landing-project-id and landing_pubsub_topic_id with output variables obtained before. Create device certificates as shown in the Simple Example and register them in devices.yaml file together with deviceids.

```hcl
module "iot-platform" {
  source     = "./iot-core"
  project_id = "landing-project-id"
  region = "europe-west1"
  telemetry_pub_sub_topic_id = "landing_pubsub_topic_id"
  status_pub_sub_topic_id = "status_pubsub_topic_id"
  devices_yaml_file = "devices.yaml"
}
# tftest:modules=1:resources=3
```
1. After that, we can setup the pipeline PubSub to BigQuery show at **[Pipeline Setup](../../data-solutions/data-platform-foundations/03-pipeline/pubsub_to_bigquery.md)**

1. Finally, instead of testing the pipeline by sending messages to PubSub, we can now test sending telemetry messages from simulated IoT devices to our IoT Platform, for example using the MQTT demo client at https://github.com/googleapis/nodejs-iot/tree/main/samples/mqtt_example . We shall edit the client script cloudiot_mqtt_example_nodejs.js to send messages following the pipeline message format
```
const payload = '{"name": "device4", "surname": "NA", "timestamp":"'+Math.floor(Date.now()/1000)+'"}';
```

Or even better, create a new BigQuery table with our IoT sensors data and modify the DataFlow job to push data to it.


<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| project_id | Project were resources will be deployed | <code title="">string</code> | ✓ |  |
| region | Region were resources will be deployed | <code title="">string</code> | ✓ |  |
| status_pub_sub_topic_id | pub sub topic for status messages (GCP-->Device) | <code title="">string</code> | ✓ |  |
| telemetry_pub_sub_topic_id | pub sub topic for telemetry messages (Device-->GCP) | <code title="">string</code> | ✓ |  |
| *devices_yaml_file* | yaml file name including Devices map to be registered in the IoT Registry in the form DEVICE_ID: DEVICE_CERTIFICATE | <code title="">string</code> |  | <code title=""></code> |
| *extra_telemetry_pub_sub_topic_ids* | additional pub sub topics for telemetry messages in adhoc MQTT topics (Device-->GCP) in the format MQTT_TOPIC:PUB_SUB_TOPIC_ID | <code title="list&#40;object&#40;&#123;&#10;mqtt_topic &#61; string&#10;pub_sub_topic &#61; string&#10;&#125;&#41;&#41;">list(object({...}))</code> |  | <code title="">[]</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| iot_registry | Cloud IoT Core Registry |  |
<!-- END TFDOC -->

