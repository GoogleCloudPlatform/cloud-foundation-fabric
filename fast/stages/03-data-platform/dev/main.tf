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
    var.network_config_composer,
    var.network_config
  )
}

module "data-platform" {
  source                  = "../../../../examples/data-solutions/data-platform-foundations"
  billing_account_id      = var.billing_account_id
  composer_config         = var.composer_config
  data_force_destroy      = var.data_force_destroy
  folder_id               = var.folder_id
  groups                  = var.groups
  network_config          = local._network_config
  organization_domain     = var.organization_domain
  prefix                  = var.prefix
  project_services        = var.project_services
  region                  = var.region
  service_encryption_keys = var.service_encryption_keys
}
