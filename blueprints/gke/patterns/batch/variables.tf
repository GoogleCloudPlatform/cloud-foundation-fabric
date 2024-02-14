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

variable "kueue_namespace" {
  description = "Namespaces of the teams running jobs in the clusters."
  type        = string
  nullable    = false
  default     = "kueue-system"
}

variable "team_namespaces" {
  description = "Namespaces of the teams running jobs in the clusters."
  type        = list(string)
  nullable    = false
  default = [
    "team-a",
    "team-b"
  ]
}

variable "templates_path" {
  description = "Path where manifest templates will be read from. Set to null to use the default manifests."
  type        = string
  default     = null
}

