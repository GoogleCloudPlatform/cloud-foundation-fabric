/**
 * Copyright 2023 Google LLC
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

variable "location_type" {
  description = "The location type of the Dataplax Lake."
  type        = string
  default     = "SINGLE_REGION"
}

variable "name" {
  description = "Name of Dataplex Lake."
  type        = string
}

variable "prefix" {
  description = "Optional prefix used to generate Dataplex Lake."
  type        = string
}

variable "project_id" {
  description = "The ID of the project where this Dataplex Lake will be created."
  type        = string
}

variable "region" {
  description = "Region of the Dataplax Lake."
  type        = string
}

variable "zones" {
  description = "Dataplex lake zones, such as `RAW` and `CURATED`."
  type = map(object({
    type      = string
    discovery = optional(bool, true)
    assets = map(object({
      bucket_name            = string
      cron_schedule          = optional(string, "15 15 * * *")
      discovery_spec_enabled = optional(bool, true)
      resource_spec_type     = optional(string, "STORAGE_BUCKET")
    }))
  }))
}
