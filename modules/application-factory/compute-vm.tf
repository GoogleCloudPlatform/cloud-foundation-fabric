/**
 * Copyright 2026 Google LLC
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

# tfdoc:file:description Phase 3: Compute VMs.

locals {
  _compute_vm_raw = {
    for f in try(fileset(local.paths.compute_vm, "*.yaml"), []) :
    trimsuffix(f, ".yaml") => yamldecode(
      file("${local.paths.compute_vm}/${f}")
    )
  }
}

module "compute-vm" {
  source   = "../compute-vm"
  for_each = local._compute_vm_raw
  project_id           = try(each.value.project_id, null)
  name                 = try(each.value.name, each.key)
  zone                 = each.value.zone
  instance_type        = try(each.value.instance_type, "f1-micro")
  description          = try(each.value.description, "Managed by the compute-vm Terraform module.")
  can_ip_forward       = try(each.value.can_ip_forward, false)
  confidential_compute = try(each.value.confidential_compute, false)
  create_template      = try(each.value.create_template, null)
  enable_display       = try(each.value.enable_display, false)
  encryption           = try(each.value.encryption, null)
  gpu                  = try(each.value.gpu, null)
  group                = try(each.value.group, null)
  hostname             = try(each.value.hostname, null)
  iam                  = try(each.value.iam, {})
  instance_schedule    = try(each.value.instance_schedule, null)
  labels               = try(each.value.labels, {})
  metadata             = try(each.value.metadata, {})
  metadata_startup_script     = try(each.value.metadata_startup_script, null)
  min_cpu_platform            = try(each.value.min_cpu_platform, null)
  network_attached_interfaces = try(each.value.network_attached_interfaces, [])
  network_interfaces          = each.value.network_interfaces
  options              = try(each.value.options, {})
  scratch_disks        = try(each.value.scratch_disks, { count = 0, interface = "NVME" })
  service_account      = try(each.value.service_account, {})
  shielded_config      = try(each.value.shielded_config, null)
  tag_bindings         = try(each.value.tag_bindings, {})
  tags                 = try(each.value.tags, [])
  boot_disk            = try(each.value.boot_disk, { initialize_params = {} })
  attached_disks       = try(each.value.attached_disks, [])
  context = merge(local.ctx, {
    iam_principals = local.ctx_iam_principals
  })
}
