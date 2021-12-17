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

variable "devices" {
  description = "Devices map to be registered in the IoT Registry in the form DEVICE_ID: DEVICE_CERTIFICATE"
  type        = map(string)
  default     = {}
}

variable "extra_telemetry_pub_sub_topic_ids" {
  description = "additional pub sub topics for telemetry messages in adhoc MQTT topics (Device-->GCP) in the format MQTT_TOPIC:PUB_SUB_TOPIC_ID"
  type = list(object({
    mqtt_topic = string
    pub_sub_topic = string
  }))
}

variable "status_pub_sub_topic_id" {
   description = "pub sub topic for status messages (GCP-->Device)"
  type = string
}

variable "telemetry_pub_sub_topic_id" {
   description = "pub sub topic for telemetry messages (Device-->GCP)"
  type = string
}