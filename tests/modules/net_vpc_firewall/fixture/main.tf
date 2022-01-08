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

module "firewall" {
  source              = "../../../../modules/net-vpc-firewall"
  project_id          = var.project_id
  network             = var.network
  admin_ranges        = var.admin_ranges
  http_source_ranges  = var.http_source_ranges
  https_source_ranges = var.https_source_ranges
  ssh_source_ranges   = var.ssh_source_ranges
  custom_rules        = var.custom_rules
  data_folder         = var.data_folder
  cidr_template_file  = var.cidr_template_file
}
