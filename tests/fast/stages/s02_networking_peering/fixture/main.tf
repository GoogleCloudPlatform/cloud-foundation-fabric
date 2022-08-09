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

module "stage" {
  source   = "../../../../../fast/stages/02-networking-peering"
  data_dir = "../../../../../fast/stages/02-networking-peering/data/"
  automation = {
    outputs_bucket = "test"
  }
  billing_account = {
    id              = "000000-111111-222222"
    organization_id = 123456789012
  }
  custom_roles = {
    service_project_network_admin = "organizations/123456789012/roles/foo"
  }
  folder_ids = {
    networking      = null
    networking-dev  = null
    networking-prod = null
  }
  region_trigram = {
    europe-west1 = "ew1"
    europe-west3 = "ew3"
    europe-west8 = "ew8"
  }
  service_accounts = {
    data-platform-dev    = "string"
    data-platform-prod   = "string"
    project-factory-dev  = "string"
    project-factory-prod = "string"
  }
  organization = {
    domain      = "fast.example.com"
    id          = 123456789012
    customer_id = "C00000000"
  }
  prefix = "fast2"
}
