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
    cluster-1 = "projects/myproject/locations/europe-west1-b/clusters/cluster-1"
    cluster-2 = "projects/myproject/locations/europe-west1-b/clusters/cluster-2"
  }
}

variable "features" {
  default = {
    appdevexperience             = false
    configmanagement             = true
    identityservice              = false
    multiclusteringress          = null
    servicemesh                  = true
    multiclusterservicediscovery = false
  }
}

variable "configmanagement_templates" {
  default = {
    default = {
      binauthz = false
      config_sync = {
        git = {
          gcp_service_account_email = null
          https_proxy               = null
          policy_dir                = "configsync"
          secret_type               = "ssh"
          sync_branch               = "main"
          sync_repo                 = "https://github.com/danielmarzini/configsync-platform-example"
          sync_rev                  = null
          sync_wait_secs            = null
        }
        prevent_drift = false
        source_format = "hierarchy"
      }
      hierarchy_controller = null
      policy_controller    = null
      version              = "1.10.2"
    }
  }
}

variable "configmanagement_clusters" {
  default = {
    default = ["cluster-1", "cluster-2"]
  }
}

variable "workload_identity_clusters" {
  default = ["mycluster1", "mycluster2"]
}
