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

# tfdoc:file:description Input variables.

variable "cluster_id" {
  description = "Cluster ID when deploying multiple clusters. Defaults to 'default'."
  type        = string
  default     = "default"
}

variable "data_disk_size" {
  description = "Size of MongoDB data disks in GB."
  type        = number
  default     = 10
}

variable "healthcheck_image" {
  description = "Container image for healthcheck."
  type        = string
}

variable "project_create" {
  description = "Create project instead ofusing an existing one."
  type        = bool
  default     = false
}

variable "project_id" {
  description = "Google Cloud project ID."
  type        = string
}

variable "region" {
  description = "Region to use."
  type        = string
  default     = "europe-west4"
}

variable "startup_image" {
  description = "Container image for cluster startup."
  type        = string
}

variable "vpc_config" {
  description = "Network and subnetwork to use."
  type = object({
    create               = bool
    network              = string
    network_project      = optional(string)
    subnetwork           = optional(string)
    subnetwork_self_link = optional(string)
  })
}
