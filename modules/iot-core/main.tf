
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

locals {
  devices_config_files = flatten(
    [
      for config_path in var.devices_config_directories :
      concat(
        [
          for config_file in fileset("${path.root}/${config_path}", "**/*.yaml") :
          "${path.root}/${config_path}/${config_file}"
        ]
      )

    ]
  )

  device_config = merge(
    [
      for config_file in local.devices_config_files :
      try(yamldecode(file(config_file)), {})
    ]...
  )
}

#---------------------------------------------------------
# Create IoT Core Registry
#---------------------------------------------------------

resource "google_cloudiot_registry" "registry" {

  name    = var.registry_name
  project = var.project_id
  region  = var.region

  dynamic "event_notification_configs" {
    for_each = var.extra_telemetry_pubsub_topic_ids
    content {
      pubsub_topic_name = event_notification_configs.value
      subfolder_matches = event_notification_configs.key
    }
  }

  event_notification_configs {
    pubsub_topic_name = var.telemetry_pubsub_topic_id
    subfolder_matches = ""
  }

  state_notification_config = {
    pubsub_topic_name = var.status_pubsub_topic_id
  }

  mqtt_config = {
    mqtt_enabled_state = var.protocols.mqtt ? "MQTT_ENABLED" : "MQTT_DISABLED"
  }

  http_config = {
    http_enabled_state = var.protocols.http ? "HTTP_ENABLED" : "HTTP_DISABLED"
  }

  log_level = var.log_level

}

#---------------------------------------------------------
# Create IoT Core Device
# certificate created using: openssl req -x509 -newkey rsa:2048 -keyout rsa_private.pem -nodes -out rsa_cert.pem -subj "/CN=unused"
#---------------------------------------------------------

resource "google_cloudiot_device" "device" {
  for_each = local.device_config
  name     = each.key
  registry = google_cloudiot_registry.registry.id

  credentials {
    public_key {
      format = each.value.certificate_format
      key    = file(each.value.certificate_file)
    }
  }

  blocked = each.value.is_blocked

  log_level = each.value.log_level

  gateway_config {
    gateway_type = each.value.is_gateway ? "GATEWAY" : "NON_GATEWAY"
  }
}