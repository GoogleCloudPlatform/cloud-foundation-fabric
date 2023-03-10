/**
 * Copyright 2023 Google LLC
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
  vms = {
    for f in fileset("${var.data_dir}", "**/*.yaml") :
    trimsuffix(f, ".yaml") => yamldecode(file("${var.data_dir}/${f}"))
  }
}

module "vm-disk-options-example" {
  source = "../../../modules/compute-vm"

  for_each               = local.vms
  project_id             = each.value.project_id
  zone                   = each.value.zone
  name                   = each.value.name
  network_interfaces     = each.value.network_interfaces
  attached_disks         = each.value.attached_disks
  service_account_create = each.value.service_account_create
}
