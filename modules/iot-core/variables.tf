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

variable "devices_blocked" {
  description = "Variable to setup devices status. blocked=false then devices are active"
  type        = bool
  default     = false
}

variable "devices_certificates_format" {
  description = "certificates format. Possible values are RSA_PEM, RSA_X509_PEM, ES256_PEM, and ES256_X509_PEM"
  type        = string
  default     = "RSA_X509_PEM"
}

variable "devices_gw_config" {
  description = "Indicates whether the device is a gateway. Default value is NON_GATEWAY. Possible values are GATEWAY and NON_GATEWAY"
  type        = string
  default     = "NON_GATEWAY"
}

variable "devices_yaml_file" {
  description = "yaml file name including Devices map to be registered in the IoT Registry in the form DEVICE_ID: DEVICE_CERTIFICATE"
  type        = string
  default     = ""
}

variable "extra_telemetry_pubsub_topic_ids" {
  description = "additional pubsub topics for telemetry messages in adhoc MQTT topics (Device-->GCP) in the format MQTT_TOPIC:PUBSUB_TOPIC_ID"
  type = list(object({
    mqtt_topic    = string
    pubsub_topic = string
  }))
  default = []
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

variable "protocol_http" {
  description = "http protocol activation. HTTP_ENABLED or HTTP_DISABLED"
  type        = string
  default     = "HTTP_ENABLED"
}

variable "protocol_mqtt" {
  description = "Matt protocol activation. MQTT_ENABLED or MQTT_DISABLED"
  type        = string
  default     = "MQTT_ENABLED"
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