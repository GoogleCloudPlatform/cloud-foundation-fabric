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

variable "image" {
  description = "Container image to use."
  type        = string
  nullable    = false
  default     = "redis:6.2"
}

variable "namespace" {
  description = "Namespace used for Redis cluster resources."
  type        = string
  nullable    = false
  default     = "redis"
}

variable "statefulset_config" {
  description = "Configure Redis cluster statefulset parameters."
  type = object({
    replicas = optional(number, 6)
    resource_requests = optional(object({
      cpu    = optional(string, "1")
      memory = optional(string, "1Gi")
    }), {})
    volume_claim_size = optional(string, "10Gi")
  })
  nullable = false
  default  = {}
  validation {
    condition     = var.statefulset_config.replicas >= 6
    error_message = "The minimum number of Redis cluster replicas is 6."
  }
}

variable "templates_path" {
  description = "Path where manifest templates will be read from. Set to null to use the default manifests."
  type        = string
  default     = null
}
