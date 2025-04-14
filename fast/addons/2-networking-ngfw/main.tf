/**
 * Copyright 2025 Google LLC
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

locals {
  aliased_project_id = lookup(
    var.host_project_ids, var.project_id, var.project_id
  )
  project_id = try(module.project[0].project_id, var.project_id)
}

module "project" {
  source        = "../../../modules/project"
  count         = var._fast_debug.skip_datasources == true ? 0 : 1
  name          = local.aliased_project_id
  project_reuse = {}
  service_agents_config = {
    services_enabled = [
      "networksecurity.googleapis.com"
    ]
  }
  services = var.enable_services != true ? [] : [
    "certificatemanager.googleapis.com",
    "networkmanagement.googleapis.com",
    "networksecurity.googleapis.com",
    "privateca.googleapis.com"
  ]
}
