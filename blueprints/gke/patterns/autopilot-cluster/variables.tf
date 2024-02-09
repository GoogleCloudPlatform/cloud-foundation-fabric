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

variable "cluster_create" {
  description = "Cluster configuration for newly created cluster. Set to null to use existing cluster, or create using defaults in new project."
  type = object({
    deletion_protection = optional(bool, true)
    labels              = optional(map(string))
    master_authorized_ranges = optional(map(string), {
      rfc-1918-10-8 = "10.0.0.0/8"
    })
    master_ipv4_cidr_block = optional(string, "172.16.255.0/28")
    vpc = optional(object({
      id        = string
      subnet_id = string
      secondary_range_names = optional(object({
        pods     = optional(string, "pods")
        services = optional(string, "services")
      }), {})
    }))
    options = optional(object({
      release_channel     = optional(string, "REGULAR")
      enable_backup_agent = optional(bool, false)
    }), {})
  })
  default = null
}

variable "cluster_name" {
  description = "Name of new or existing cluster."
  type        = string
}

variable "fleet_project_id" {
  description = "GKE Fleet project id. If null cluster project will also be used for fleet."
  type        = string
  default     = null
}

variable "prefix" {
  description = "Prefix used for resource names."
  type        = string
  nullable    = false
  default     = "jump-0"
}

variable "project_create" {
  description = "Project configuration for newly created project. Leave null to use existing project. Project creation forces VPC and cluster creation."
  type = object({
    billing_account = string
    parent          = optional(string)
    shared_vpc_host = optional(string)
  })
  default = null
}

variable "project_id" {
  description = "Project id of existing or created project."
  type        = string
}

variable "region" {
  description = "Region used for cluster and network resources."
  type        = string
}

variable "registry_create" {
  description = "Create remote Docker Artifact Registry."
  type        = bool
  default     = true
}

variable "vpc_create" {
  description = "Project configuration for newly created VPC. Leave null to use existing VPC, or defaults when project creation is required."
  type = object({
    name                     = optional(string)
    subnet_name              = optional(string)
    primary_range_nodes      = optional(string, "10.0.0.0/24")
    secondary_range_pods     = optional(string, "10.16.0.0/20")
    secondary_range_services = optional(string, "10.32.0.0/24")
    enable_cloud_nat         = optional(bool, false)
    proxy_only_subnet        = optional(string)
  })
  default = null
}
