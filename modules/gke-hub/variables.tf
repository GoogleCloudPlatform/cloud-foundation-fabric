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

variable "member_clusters" {
  description = "Clusters members of this GKE Hub in name => id format."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "member_configs" {
  description = "Sets of feature configurations that can be applied to member clusters, in config name => {options} format."
  type = map(object({
    binauthz                  = bool
    config_management_version = string
    hierarchy_controller = object({
      hierarchical_resource_quota = bool
      pod_tree_labels             = bool
    })
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
    multi_cluster_ingress = bool
    multi_cluster_service = bool
    service_mesh          = bool
    policy_controller = object({
      exemptable_namespaces      = list(string)
      log_denies_enabled         = bool
      referential_rules_enabled  = bool
      template_library_installed = bool
    })
  }))
  default  = {}
  nullable = false
}

variable "member_features" {
  description = "Features enabled on specific sets of member clusters, in config name => [cluster name] format."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "project_id" {
  description = "GKE hub project ID."
  type        = string
}
