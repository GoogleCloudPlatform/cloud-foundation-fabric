/**
 * Copyright 2026 Google LLC
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

variable "context" {
  description = "Context-specific interpolations."
  type = object({
    locations   = optional(map(string), {})
    networks    = optional(map(string), {})
    project_ids = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

variable "excluded_networks" {
  description = "List of network URLs to explicitly exclude from threat detector protection."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "labels" {
  description = "Set of label tags associated with the DNS Threat Detector."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "location" {
  description = "The location of the DNS Threat Detector. Currently only global is supported."
  type        = string
  default     = null
}

variable "name" {
  description = "Name of the DNS Threat Detector."
  type        = string
}

variable "prefix" {
  description = "Optional prefix applied to resource name."
  type        = string
  default     = null
}

variable "project_id" {
  description = "ID of the project where the resource stays."
  type        = string
}

variable "threat_detector_provider" {
  description = "DNS Threat Detection provider. Only supported value is INFOBLOX."
  type        = string
  default     = null
}
