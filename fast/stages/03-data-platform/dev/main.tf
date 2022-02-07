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

# tfdoc:file:description Data Platformy.

locals {
  _network_config = merge(
    #TODO Ask
    {
      composer_ip_ranges = {
        cloudsql   = "172.18.29.0/24"
        gke_master = "172.18.30.0/28"
        web_server = "172.18.30.16/28"
      }
      composer_secondary_ranges = {
        pods     = "pods"
        services = "services"
      }
    },
    var.network_config
  )
  _project_create = {
    billing_account_id = var.billing_account_id
    parent             = var.folder_id
  }
}

module "data-platform" {
  source = "../../../../examples/data-solutions/data-platform-foundations"
  organization = {
    domain = var.organization.domain
  }
  prefix                  = var.prefix
  composer_config         = var.composer_config
  data_force_destroy      = var.data_force_destroy
  groups                  = var.groups
  location_config         = var.location_config
  network_config          = local._network_config
  project_create          = local._project_create
  project_id              = var.project_id
  project_services        = var.project_services
  service_encryption_keys = var.service_encryption_keys
}
