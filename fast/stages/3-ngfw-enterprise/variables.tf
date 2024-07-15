/**
 * Copyright 2024 Google LLC
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

variable "factories_config" {
  description = "Configuration for network resource factories."
  type = object({
    data_dir = optional(string, "data")
  })
  default  = {}
  nullable = false
  validation {
    condition     = var.factories_config.data_dir != null
    error_message = "Data folder needs to be non-null."
  }
}

variable "ngfw_enterprise_config" {
  description = "NGFW Enterprise configuration."
  type = object({
    endpoint_zones = optional(list(string), ["europe-west1-a", "europe-west1-b", "europe-west1-c"])
  })
  nullable = false
  default  = {}
}
