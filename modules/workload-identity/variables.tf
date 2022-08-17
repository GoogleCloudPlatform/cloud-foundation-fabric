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

variable "display_name" {
  type        = string
  description = "Display name for the pool."
  default     = ""
}

variable "disabled" {
  type        = bool
  description = "Disable pool usage."
  default     = false
}

variable "pool_id" {
  type        = string
  description = "Pool ID."
}

variable "project_id" {
  type        = string
  description = "Project used for resources."
}

variable "provider_id" {
  type        = string
  description = "Pool provider ID."
}
variable "provider_display_name" {
  type        = string
  description = "Display name for the provider."
  default     = ""
}
variable "provider_disabled" {
  type        = bool
  description = "Disable provider usage."
  default     = false
}
variable "provider_attribute_condition" {
  type        = string
  description = "Conditions provider won't allow."
  default     = null
}
variable "provider_attribute_mapping" {
  type        = map(string)
  description = "Mapping to an external provider."
  default = {
    "google.subject" = "assertion.sub"
  }
}

variable "provider_config" {
  type        = map(any)
  description = "OIDC or AWS support"
}