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

# optional enabling the api

variable "features" {
  description = "value"
  type        = map(bool)
  default = {
    configmanagement             = true
    multiclusteringress          = false
    multiclusterservicediscovery = false
  }
}

variable "member_clusters" {
  description = "value"
  type        = map(string)
  default     = {}
}

variable "member_features" {
  description = ""
  type = object({
    configmanagement = object({
      version = string
      config_sync = object({
        https_proxy               = string
        sync_repo                 = string
        sync_branch               = string
        sync_rev                  = string
        secret_type               = string
        gcp_service_account_email = string
        policy_dir                = string
        source_format             = string
      })
      policy_controller = object({
        enabled                    = bool
        log_denies_enabled         = bool
        referential_rules_enabled  = bool
        exemptable_namespaces      = list(string)
        template_library_installed = bool
      })
      binauthz = object({
        enabled = bool
      })
      hierarchy_controller = object({
        enabled                            = bool
        enable_pod_tree_labels             = bool
        enable_hierarchical_resource_quota = bool
      })
    })
    multiclusteringress          = bool
    multiclusterservicediscovery = bool
  })
  default = null
}

variable "project_id" {
  description = "Cluster project ID."
  type        = string
}
