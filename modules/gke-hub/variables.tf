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

variable "config_sync_defaults" {
  description = "Default values for optional config_sync configurations."
  type = object({
    repository_url           = string
    repository_branch        = string
    repository_source_format = string
    repository_policy_dir    = string
    workload_identity_sa     = string
    secret_type              = string
  })
  default = {
    repository_url           = null
    repository_branch        = "main"
    repository_source_format = "hierarchy"
    repository_policy_dir    = "configsync"
    workload_identity_sa     = null
    secret_type              = "gcpserviceaccount"
  }
}

variable "policy_controller_defaults" {
  description = "Default values for optional config_sync configurations."
  type = object({
    enable_template_library = bool
    enable_log_denies       = bool
    exemptable_namespaces   = list(string)
  })
  default = {
    enable_template_library = true
    enable_log_denies       = true
    exemptable_namespaces   = ["config-management-monitoring", "config-management-system"]
  }
}

variable "hub_config" {
  description = ""
  type = object({
    clusters = list(map(string))
    policy_controller = object({
      enable_template_library = bool
      enable_log_denies       = bool
      exemptable_namespaces   = list(string)
    })
    config_sync = object({
      repository_url           = string
      repository_branch        = string
      repository_source_format = string
      repository_policy_dir    = string
      workload_identity_sa     = string
    })
  })
}

# gcp_service_account_email = string
# secret_type = string

variable "project_id" {
  description = "Cluster project id."
  type        = string
}
