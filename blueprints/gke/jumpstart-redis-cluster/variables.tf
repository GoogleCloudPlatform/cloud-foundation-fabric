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

variable "cluster_create_config" {
  description = "Cluster-level configuration."
  type = object({
    master_authorized_ranges = optional(map(string), {
      "10/8" = "10.0.0.0/8"
    })
    master_ipv4_cidr_block = optional(string, "172.16.20.0/28")
    private_cluster = optional(object({
      enable_private_endpoint = optional(bool, true)
      master_global_access    = optional(bool, true)
    }), {})
  })
  # null do not creates cluster
  default = null
}

variable "enable_fleet" {
  description = "Enable fleet management for the cluster in the same project."
  type        = bool
  default     = true
}

variable "create_config" {
  description = "Create prerequisite resources, fill if project creation is needed."
  type = object({
    billing_account = optional(string)
    project_parent  = optional(string)
    vpc = object({
      primary_range_nodes      = string
      secondary_range_pods     = string
      secondary_range_services = string
    })
  })
  default = null
}

variable "kubeconfig_path" {
  type    = string
  default = null
}

variable "project_id" {
  description = "Project id of existing or created project."
  type        = string
  default     = null
  # use an existing cluster we don't care about GCP resources
}

variable "region" {
  description = "Region used for cluster and network resources."
  type        = string
  default     = "europe-west8"
}

# assumptions
# - user provides a cluster
# - user provides everything (project, svpc or vpc, etc.)
#   - enable services
#   - IAM on host / local for robots
# - we create everything

