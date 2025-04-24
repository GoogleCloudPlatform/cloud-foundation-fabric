/**
 * Copyright 2025 Google LLC
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

variable "capacity_config" {
  description = "Capacity configuration for the Kafka cluster."
  type = object({
    vcpu_count   = number
    memory_bytes = number
  })
}

variable "cluster_id" {
  description = "The ID of the Kafka cluster."
  type        = string
}

variable "connect_clusters" {
  description = "Map of Kafka Connect cluster configurations to create."
  type = map(object({
    vcpu_count         = number
    memory_bytes       = number
    primary_subnet     = string
    project_id         = optional(string)
    location           = optional(string)
    additional_subnets = optional(list(string))
    dns_domain_names   = optional(list(string))
    labels             = optional(map(string))
  }))
  default  = {}
  nullable = false
}

variable "connect_connectors" {
  description = "Map of Kafka Connect Connectors to create."
  type = map(object({
    connect_cluster = string
    configs         = map(string)
    task_restart_policy = optional(object({
      minimum_backoff = optional(string)
      maximum_backoff = optional(string)
    }))
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.connect_connectors :
      contains(keys(var.connect_clusters), v.connect_cluster)
    ])
    error_message = "The connect_cluster attribute of all connectors must be one of the keys in the connect_clusters variable."
  }
}

variable "kms_key" {
  description = "Customer-managed encryption key (CMEK) used for the Kafka cluster."
  type        = string
  default     = null
}

variable "labels" {
  description = "Labels to apply to the Kafka cluster."
  type        = map(string)
  default     = null
}

variable "location" {
  description = "The GCP region for the Kafka cluster."
  type        = string
}

variable "project_id" {
  description = "The ID of the project where the Kafka cluster will be created."
  type        = string
}

variable "rebalance_mode" {
  description = "Rebalancing mode for the Kafka cluster."
  type        = string
  default     = null
}

variable "subnets" {
  description = "List of VPC subnets for the Kafka cluster network configuration."
  type        = list(string)
}

variable "topics" {
  description = "Map of Kafka topics to create within the cluster."
  type = map(object({
    replication_factor = number
    partition_count    = number
    configs            = optional(map(string))
  }))
  default  = {}
  nullable = false
}
