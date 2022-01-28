/**
 * Copyright 2022 Google LLC
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

variable "devices_config" {
  description = "IoT configuration for the batch of devices to be configured. Certificates format values are RSA_PEM, RSA_X509_PEM, ES256_PEM, and ES256_X509_PEM. yaml_file name including Devices map to be registered in the IoT Registry in the form DEVICE_ID: DEVICE_CERTIFICATE"
  type = object({
    blocked            = bool,
    certificate_format = string,
    gateway            = bool,
    yaml_file          = string,
    log_level          = string
  })
  default = { blocked = false, certificate_format = "RSA_X509_PEM", gateway = false, yaml_file = "", log_level = "INFO" }
}

variable "extra_telemetry_pubsub_topic_ids" {
  description = "additional pubsub topics linked to adhoc MQTT topics (Device-->GCP) in the format MQTT_TOPIC: PUBSUB_TOPIC_ID"
  type        = map(string)
  default     = {}
}

variable "log_level" {
  description = "IoT Registry Log level"
  type        = string
  default     = "INFO"
}

variable "project_id" {
  description = "Project were resources will be deployed"
  type        = string
}

variable "protocols" {
  description = "IoT protocols (HTTP / MQTT) activation"
  type = object({
    http = bool,
    mqtt = bool
  })
  default = { http = true, mqtt = true }
}

variable "region" {
  description = "Region were resources will be deployed"
  type        = string
}

variable "registry_name" {
  description = "Name for the IoT Core Registry"
  type        = string
  default     = "cloudiot-registry"
}

variable "status_pubsub_topic_id" {
  description = "pub sub topic for status messages (GCP-->Device)"
  type        = string
}

variable "telemetry_pubsub_topic_id" {
  description = "pub sub topic for telemetry messages (Device-->GCP)"
  type        = string
}