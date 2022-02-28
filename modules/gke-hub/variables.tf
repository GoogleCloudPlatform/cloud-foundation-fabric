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

variable "features" {
  description = "GKE hub features to enable."
  type = object({
    configmanagement    = bool
    mc_ingress          = bool
    mc_servicediscovery = bool
  })
  default = {
    configmanagement    = true
    mc_ingress          = false
    mc_servicediscovery = false
  }
  nullable = false
}

variable "member_clusters" {
  description = "List for member cluster self links."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "member_features" {
  description = "Member features for each cluster"
  type = object({
    configmanagement = object({
      binauthz = bool
      config_sync = object({
        gcp_service_account_email = string
        https_proxy               = string
        policy_dir                = string
        secret_type               = string
        source_format             = string
        sync_branch               = string
        sync_repo                 = string
        sync_rev                  = string
      })
      hierarchy_controller = object({
        enable_hierarchical_resource_quota = bool
        enable_pod_tree_labels             = bool
      })
      policy_controller = object({
        exemptable_namespaces      = list(string)
        log_denies_enabled         = bool
        referential_rules_enabled  = bool
        template_library_installed = bool
      })
      version = string
    })
    # mc-ingress          = bool
    # mc-servicediscovery = bool
  })
  default = {
    configmanagement = null
  }
  nullable = false
}

variable "project_id" {
  description = "GKE hub project ID."
  type        = string
}
