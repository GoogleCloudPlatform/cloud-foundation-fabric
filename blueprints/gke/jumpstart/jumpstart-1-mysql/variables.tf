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
  type = object({
    version          = optional(string, "8.0.32") # latest is 8.0.32, originally was with 8.0.28 / 8.0.27
    db_replicas      = optional(number, 3)        # cannot be higher than number of the zones in region
    db_cpu           = optional(string, "500m")
    db_memory        = optional(string, "1Gi")
    db_database_size = optional(string, "10Gi")
    router_replicas  = optional(number, 2) # cannot be higher than number of the zones in region
    router_cpu       = optional(string, "500m")
    router_memory    = optional(string, "2Gi")
  })
  nullable = false
  default  = {}
  validation {
    condition     = var.mysql_config.db_replicas >= 3
    error_message = "db_replicas must be 3 or greater (but no larger than number of available zones in the region)"
  }
}

variable "namespace" {
  description = "Namespace used for MySQL cluster resources."
  type        = string
  nullable    = false
  default     = "mysql1"
}

variable "registry_path" {
  type     = string
  nullable = false
}

variable "templates_path" {
  description = "Path where manifest templates will be read from. Set to null to use the default manifests"
  type        = string
  default     = null
}

