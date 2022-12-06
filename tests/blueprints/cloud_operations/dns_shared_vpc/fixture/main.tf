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
  source             = "../../../../../blueprints/cloud-operations/dns-shared-vpc"
  billing_account_id = "111111-222222-333333"
  folder_id          = "folders/1234567890"
  prefix             = var.prefix
  shared_vpc_link    = "https://www.googleapis.com/compute/v1/projects/test-dns/global/networks/default"
  teams              = var.teams
}
