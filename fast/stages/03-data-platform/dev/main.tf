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

module "data-platform" {
  source             = "../../../../examples/data-solutions/data-platform-foundations"
  billing_account_id = var.billing_account.id
  composer_config    = var.composer_config
  data_force_destroy = var.data_force_destroy
  folder_id          = var.folder_ids.data-platform
  groups             = var.groups
  network_config = {
    host_project      = var.host_project_ids.dev-spoke-0
    network_self_link = var.vpc_self_links.dev-spoke-0
    subnet_self_links = {
      load           = var.subnet_self_links.dev-spoke-0["europe-west1/dev-dataplatform-ew1"]
      transformation = var.subnet_self_links.dev-spoke-0["europe-west1/dev-dataplatform-ew1"]
      orchestration  = var.subnet_self_links.dev-spoke-0["europe-west1/dev-dataplatform-ew1"]
    }
    # TODO: align example variable
    composer_ip_ranges = {
      cloudsql   = var.network_config_composer.cloudsql_range
      gke_master = var.network_config_composer.gke_master_range
      web_server = var.network_config_composer.web_server_range
    }
    composer_secondary_ranges = {
      pods     = var.network_config_composer.gke_pods_name
      services = var.network_config_composer.gke_services_name
    }
  }
  organization_domain     = var.organization.domain
  prefix                  = "${var.prefix}-dev-data"
  project_services        = var.project_services
  project_suffix          = "0"
  region                  = var.region
  service_encryption_keys = var.service_encryption_keys
}
