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

variable "clusters" {
  description = "Clusters members of this GKE Hub in name => id format."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "configmanagement_clusters" {
  description = "Config management features enabled on specific sets of member clusters, in config name => [cluster name] format."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "configmanagement_templates" {
  description = "Sets of config management configurations that can be applied to member clusters, in config name => {options} format."
  type = map(object({
    binauthz = optional(bool)
    version  = optional(string)
    config_sync = object({
      git = optional(object({
        sync_repo                 = string
        policy_dir                = string
        gcp_service_account_email = optional(string)
        https_proxy               = optional(string)
        secret_type               = optional(string, "none")
        sync_branch               = optional(string)
        sync_rev                  = optional(string)
        sync_wait_secs            = optional(number)
      }))
      prevent_drift = optional(bool)
      source_format = optional(string, "hierarchy")
    })
    hierarchy_controller = optional(object({
      enable_hierarchical_resource_quota = optional(bool)
      enable_pod_tree_labels             = optional(bool)
    }))
    policy_controller = object({
      audit_interval_seconds     = optional(number)
      exemptable_namespaces      = optional(list(string))
      log_denies_enabled         = optional(bool)
      referential_rules_enabled  = optional(bool)
      template_library_installed = optional(bool)
    })
  }))
  default  = {}
  nullable = false
}

variable "features" {
  description = "Enable and configure fleet features."
  type = object({
    appdevexperience             = optional(bool, false)
    configmanagement             = optional(bool, false)
    identityservice              = optional(bool, false)
    multiclusteringress          = optional(string, null)
    multiclusterservicediscovery = optional(bool, false)
    servicemesh                  = optional(bool, false)
  })
  default  = {}
  nullable = false
}

variable "project_id" {
  description = "GKE hub project ID."
  type        = string
}

variable "workload_identity_clusters" {
  description = "Clusters that will use Fleet Workload Identity."
  type        = list(string)
  default     = []
  nullable    = false
}
