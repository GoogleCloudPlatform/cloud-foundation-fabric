/**
 * Copyright 2020 Google LLC
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
  source     = "../../../../modules/compute-vm"
  project_id = "my-project"
  region     = "europe-west1"
  zone       = "europe-west1-b"
  name       = "test"
  network_interfaces = [{
    network    = "https://www.googleapis.com/compute/v1/projects/my-project/global/networks/default",
    subnetwork = "https://www.googleapis.com/compute/v1/projects/my-project/regions/europe-west1/subnetworks/default-default",
    nat        = false,
    addresses  = null
  }]
  service_account_create = var.service_account_create
  instance_count         = var.instance_count
  use_instance_template  = var.use_instance_template
  group                  = var.group
  iam_roles              = var.iam_roles
  iam_members            = var.iam_members
}
