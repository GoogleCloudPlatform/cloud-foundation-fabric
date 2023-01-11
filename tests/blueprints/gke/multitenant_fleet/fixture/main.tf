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

module "test" {
  source             = "../../../../../blueprints/gke/multitenant-fleet"
  project_id         = "test-prj"
  billing_account_id = "ABCDEF-0123456-ABCDEF"
  folder_id          = "folders/1234567890"
  prefix             = "test"
  clusters = {
    cluster-0 = {
      location = "europe-west1"
      private_cluster_config = {
        enable_private_endpoint = true
        master_global_access    = true
      }
      vpc_config = {
        subnetwork             = "projects/my-host-project-id/regions/europe-west1/subnetworks/mycluster-subnet"
        master_ipv4_cidr_block = "172.16.10.0/28"
        secondary_range_names = {
          pods     = "pods"
          services = "services"
        }
      }
    }
  }
  nodepools = {
    cluster-0 = {
      nodepool-0 = {
        node_config = {
          disk_type    = "pd-balanced"
          machine_type = "n2-standard-4"
          spot         = true
        }
      }
    }
  }
  vpc_config = {
    host_project_id = "my-host-project-id"
    vpc_self_link   = "projects/my-host-project-id/global/networks/my-network"
  }
}
