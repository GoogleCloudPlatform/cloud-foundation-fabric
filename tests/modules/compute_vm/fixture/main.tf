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
  source                 = "../../../../modules/compute-vm"
  project_id             = "my-project"
  zone                   = "europe-west1-b"
  name                   = "test"
  attached_disks         = var.attached_disks
  attached_disk_defaults = var.attached_disk_defaults
  create_template        = var.create_template
  confidential_compute   = var.confidential_compute
  group                  = var.group
  iam                    = var.iam
  metadata               = var.metadata
  network_interfaces     = var.network_interfaces
  service_account_create = var.service_account_create
}
