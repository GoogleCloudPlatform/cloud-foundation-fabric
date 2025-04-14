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

# Input variable definitions
variable "project_id" {
  type        = string
  description = "The ID of the Google Cloud project where the Kafka cluster will be deployed"
}

variable "kafka_config" {
  type = object({
    cluster_id     = string
    region         = string
    vcpu_count     = optional(number, 4)           # Default to 4 vCPUs
    memory_bytes   = optional(number, 21474836480) # Default to 20 GB (in bytes)
    subnetworks    = list(string)
    rebalance_mode = optional(string, "NO_REBALANCE")
  })
  description = "Configuration for the Kafka cluster"

  validation {
    condition     = contains(["MODE_UNSPECIFIED", "NO_REBALANCE", "AUTO_REBALANCE_ON_SCALE_UP"], var.kafka_config.rebalance_mode)
    error_message = "The rebalance_mode must be one of: MODE_UNSPECIFIED, NO_REBALANCE, AUTO_REBALANCE_ON_SCALE_UP."
  }
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = "Additional labels for the Kafka cluster"
}

variable "network_project_ids" {
  type        = list(string)
  description = "List of project IDs where the subnets are located"
}

variable "topics" {
  type = list(object({
    topic_id           = string
    partition_count    = optional(number, 3)
    replication_factor = optional(number, 1)
    configs            = optional(map(string), {})
  }))
  description = "The list of topics to create in the Kafka cluster."
  default     = []
}