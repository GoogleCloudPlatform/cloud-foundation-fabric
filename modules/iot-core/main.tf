
/**
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
 
#---------------------------------------------------------
# Create IoT Core Registry
#---------------------------------------------------------

resource "google_cloudiot_registry" "test-registry" {
  
  name     = "cloudiot-registry"
  project  = var.project_id
  region   = var.region
  
  dynamic "event_notification_configs" {
    for_each = var.extra_telemetry_pub_sub_topic_ids
    content {
      pubsub_topic_name = event_notification_configs.value.pub_sub_topic
      subfolder_matches = event_notification_configs.value.mqtt_topic
    }
  }

  event_notification_configs {
    pubsub_topic_name = var.telemetry_pub_sub_topic_id
    subfolder_matches = ""
  }

  state_notification_config = {
    pubsub_topic_name = var.status_pub_sub_topic_id
  }

  mqtt_config = {
    mqtt_enabled_state = "MQTT_ENABLED"
  }

  http_config = {
    http_enabled_state = "HTTP_ENABLED"
  }

  log_level = "INFO"

}

#---------------------------------------------------------
# Create IoT Core Device
# certificate created using: openssl req -x509 -newkey rsa:2048 -keyout rsa_private.pem -nodes -out rsa_cert.pem -subj "/CN=unused"
#---------------------------------------------------------

resource "google_cloudiot_device" "device" {
  for_each = coalesce(yamldecode(file(var.devices_yaml_file)), {})
  name     = each.key
  registry = google_cloudiot_registry.test-registry.id

  credentials {
    public_key {
        format = "RSA_X509_PEM"
        key = file(each.value)
    }
  }

  blocked = false

  log_level = "INFO"

  metadata = {
    test_key_1 = "test_value_1"
  }

  gateway_config {
    gateway_type = "NON_GATEWAY"
  }
}