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

variable "created_resources" {
  description = "IDs of the resources created by autopilot cluster to be consumed here."
  type = object({
    vpc_id    = string
    subnet_id = string
  })
  nullable = false
}

variable "credentials_config" {
  description = "Configure how Terraform authenticates to the cluster."
  type = object({
    fleet_host = optional(string)
    kubeconfig = optional(object({
      context = optional(string)
      path    = optional(string, "~/.kube/config")
    }))
  })
  nullable = false
  validation {
    condition = (
      (var.credentials_config.fleet_host != null) !=
      (var.credentials_config.kubeconfig != null)
    )
    error_message = "Exactly one of fleet host or kubeconfig must be set."
  }
}

variable "mysql_config" {
  description = "Configure MySQL server and router instances."
  type = object({
    db_cpu           = optional(string, "500m")
    db_database_size = optional(string, "10Gi")
    db_memory        = optional(string, "1Gi")
    db_replicas      = optional(number, 3)
    ip_address       = optional(string)
    router_replicas  = optional(number, 2) # cannot be higher than number of the zones in region
    router_cpu       = optional(string, "500m")
    router_memory    = optional(string, "2Gi")
    version          = optional(string, "8.0.34") # latest is 8.0.34, originally was with 8.0.28 / 8.0.27,
  })
  nullable = false
  default  = {}
}

variable "namespace" {
  description = "Namespace used for MySQL cluster resources."
  type        = string
  nullable    = false
  default     = "mysql1"
}

variable "project_id" {
  description = "Project to deploy bastion host."
  type        = string
}

variable "region" {
  description = "Region used for cluster and network resources."
  type        = string
}

variable "registry_path" {
  description = "Repository path for images. Default is to use Docker Hub images."
  type        = string
  nullable    = false
  default     = "docker.io"
}

variable "templates_path" {
  description = "Path where manifest templates will be read from. Set to null to use the default manifests."
  type        = string
  default     = null
}
