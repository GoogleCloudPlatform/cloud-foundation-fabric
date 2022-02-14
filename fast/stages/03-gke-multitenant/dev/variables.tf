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

# we deal with one env here
# 1 project, m clusters
# cloud dns for gke?

# variable "authenticator_security_group" {
#   description = "Optional group used for Groups for GKE."
#   type        = string
#   default     = null
# }

variable "billing_account_id" {
  # tfdoc:variable:source 00-bootstrap
  description = "Billing account id."
  type        = string
}

variable "cluster_defaults" {
  description = "Default values for optional cluster configurations."
  type = object({
    cloudrun_config             = bool
    database_encryption_key     = string
    enable_binary_authorization = bool
    master_authorized_ranges    = map(string)
    max_pods_per_node           = number
    pod_security_policy         = bool
    release_channel             = string
    vertical_pod_autoscaling    = bool
  })
  default = {
    # TODO: review defaults
    cloudrun_config             = false
    database_encryption_key     = null
    enable_binary_authorization = false
    master_authorized_ranges = {
      rfc1918_1 = "10.0.0.0/8"
      rfc1918_2 = "172.16.0.0/12"
      rfc1918_3 = "192.168.0.0/16"
    }
    max_pods_per_node        = 110
    pod_security_policy      = false
    release_channel          = "STABLE"
    vertical_pod_autoscaling = false
  }
}

variable "clusters" {
  description = ""
  type = map(object({
    cluster_autoscaling = object({
      cpu_min    = number
      cpu_max    = number
      memory_min = number
      memory_max = number
    })
    description = string
    dns_domain  = string
    labels      = map(string)
    location    = string
    net = object({
      master_range = string
      pods         = string
      services     = string
      subnet       = string
    })
    overrides = object({
      cloudrun_config             = bool
      database_encryption_key     = string
      enable_binary_authorization = bool
      master_authorized_ranges    = map(string)
      max_pods_per_node           = number
      pod_security_policy         = bool
      release_channel             = string
      vertical_pod_autoscaling    = bool
    })
  }))
}

variable "dns_domain" {
  description = "Domain name used for clusters, prefix by each cluster name. Leave null to disable Cloud DNS for GKE."
  type        = string
  default     = null
}

variable "environment" {
  # tfdoc:variable:source 01-resman
  description = "Environment abbreviation."
  type        = string
}

variable "folder_id" {
  # tfdoc:variable:source 01-resman
  description = "Folder to be used for the networking resources in folders/nnnn format."
  type        = string
}

variable "labels" {
  description = "Project-level labels."
  type        = map(string)
  default     = {}
}

variable "nodepool_defaults" {
  description = ""
  type = object({
    image_type        = string
    max_pods_per_node = number
    node_locations    = list(string)
    node_tags         = list(string)
    node_taints       = list(string)
  })
  default = {
    image_type        = "COS_CONTAINERD"
    max_pods_per_node = 110
    node_locations    = null
    node_tags         = null
    node_taints       = []
  }
}

variable "nodepools" {
  description = ""
  type = map(map(object({
    node_count         = number
    node_type          = string
    initial_node_count = number
    overrides = object({
      image_type        = string
      max_pods_per_node = number
      node_locations    = list(string)
      node_tags         = list(string)
      node_taints       = list(string)
    })
    preemptible = bool
  })))
}

variable "prefix" {
  description = "Prefix used for resources that need unique names."
  type        = string
}

variable "shared_vpc_self_link" {
  # tfdoc:variable:source 02-networking
  description = "Self link for the shared VPC."
  type        = string
  default     = null
}

variable "vpc_host_project" {
  # tfdoc:variable:source 02-networking
  description = "Host project for the shared VPC."
  type        = string
}
