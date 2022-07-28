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

variable "project_id" {
  default = "my-project"
}

variable "clusters" {
  default = {
    mycluster1 = "projects/myproject/locations/europe-west1-b/clusters/mycluster1"
    mycluster2 = "projects/myproject/locations/europe-west1-b/clusters/mycluster2"
  }
}

variable "features" {
  default = {
    cloudrun               = false
    configmanagement       = true
    identity-service       = false
    ingress                = null
    multi-cluster-services = false
    servicemesh            = false
  }
}

variable "configmanagement_templates" {
  default = {
    "common" = {
      binauthz = true
      config_sync = {
        git = {
          gcp_service_account_email = null
          https_proxy               = null
          policy_dir                = "."
          secret_type               = "ssh"
          sync_branch               = "main"
          sync_repo                 = "git@github.com:my-org/repo.git"
          sync_rev                  = null
          sync_wait_secs            = 60
        }
        prevent_drift = true
        source_format = "unstructured"
      }
      hierarchy_controller = {
        enable_hierarchical_resource_quota = true
        enable_pod_tree_labels             = true
      }
      policy_controller = {
        audit_interval_seconds = 120
        exemptable_namespaces = [
          "namespace-1",
          "namespace-2",
        ]
        log_denies_enabled         = true
        referential_rules_enabled  = true
        template_library_installed = true
      }
      version = "v1"
    }
  }
}

variable "configmanagement_clusters" {
  default = {
    "common" = ["mycluster1", "mycluster2"]
  }
}

variable "workload_identity_clusters" {
  default = ["mycluster1", "mycluster2"]
}
