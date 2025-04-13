# Input variable definitions
variable "project_id" {
  type        = string
  description = "The ID of the Google Cloud project where the Kafka cluster will be deployed"
}

variable "kafka_cluster_id" {
  type        = string
  description = "Unique ID for the Kafka cluster"
}

variable "kafka_region" {
  type        = string
  description = "The region where the Kafka cluster will be deployed"
}

variable "kafka_vcpu_count" {
  type        = number
  description = "The number of vCPUs for the Kafka cluster"
}

variable "kafka_memory_bytes" {
  type        = number
  description = "The amount of memory in bytes for the Kafka cluster"
}

variable "kafka_subnetworks" {
  type        = list(string)
  description = "List of subnetworks for the Kafka cluster"
}

variable "kafka_rebalance_mode" {
  type        = string
  default     = "AUTO_REBALANCE_ON_SCALE_UP"
  description = "The rebalance mode for the Kafka cluster"
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