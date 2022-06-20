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

# tfdoc: Data platform stage test

module "stage" {
  source = "../../../../../fast/stages/03-data-platform/dev/"
  automation = {
    outputs_bucket = "test"
  }
  billing_account = {
    id              = "012345-67890A-BCDEF0",
    organization_id = 123456
  }
  folder_ids = {
    data-platform = "folders/12345678"
  }
  host_project_ids = {
    dev-spoke-0 = "fast-dev-net-spoke-0"
  }
  organization = {
    domain      = "example.com"
    id          = 123456789012
    customer_id = "A11aaaaa1"
  }
  prefix = "fast"
  subnet_self_links = {
    dev-spoke-0 = {
      "europe-west1/dev-dataplatform-ew1" : "https://www.googleapis.com/compute/v1/projects/fast-dev-net-spoke-0/regions/europe-west1/subnetworks/dev-dataplatform-ew1",
      "europe-west1/dev-default-ew1" : "https://www.googleapis.com/compute/v1/projects/fast-dev-net-spoke-0/regions/europe-west1/subnetworks/dev-default-ew1"
    }
  }
  vpc_self_links = { dev-spoke-0 = "https://www.googleapis.com/compute/v1/projects/fast-dev-net-spoke-0/global/networks/dev-spoke-0" }
}
