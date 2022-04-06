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

module "gke-hub" {
  source     = "../../../../modules/gke-hub"
  project_id = module.gke-project-0.project_id
  member_clusters = {
    for cluster_id in keys(var.clusters) :
    cluster_id => module.gke-cluster[cluster_id].id
  }
  member_features = {
    configmanagement = {
      binauthz = false
      config_sync = {
        gcp_service_account_email = null
        https_proxy               = null
        policy_dir                = "fast/stages/03-gke-multitenant/config"
        secret_type               = "none"
        source_format             = "hierarchy"
        sync_branch               = "fast-dev-gke-marzi-rebase"
        sync_repo                 = "https://github.com/GoogleCloudPlatform/cloud-foundation-fabric"
        sync_rev                  = null
      }
      hierarchy_controller = null
      policy_controller = {
        exemptable_namespaces = [
          "asm-system",
          "config-management-system",
          "config-management-monitoring",
          "gatekeeper-system",
          "kube-system",
          "cos-auditd"
        ]
        log_denies_enabled         = true
        referential_rules_enabled  = false
        template_library_installed = true
      }
      version = "1.10.2"
    }
  }
}
