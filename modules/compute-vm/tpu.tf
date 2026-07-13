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

locals {
  is_tpu_queued = local.is_tpu && !local.is_template && try(var.tpu_config.queued, true)
  is_tpu_direct = local.is_tpu && !local.is_template && !local.is_tpu_queued
  tpu_accelerator_type = try(lookup(
    local.tpu_machine_type_to_accelerator_type, var.machine_type, var.machine_type
  ), null)
  tpu_machine_type_to_accelerator_type = {
    # TPU v5e (Lite)
    "ct5lp-hightpu-1t" = "v5litepod-1"
    "ct5lp-hightpu-4t" = "v5litepod-4"
    "ct5lp-hightpu-8t" = "v5litepod-8"
    # TPU v5p
    "ct5p-hightpu-4t" = "v5p-8"
    # TPU v6e (Trillium)
    "ct6e-standard-1t" = "v6e-1"
    "ct6e-standard-4t" = "v6e-4"
    "ct6e-standard-8t" = "v6e-8"
  }
}

check "tpu_machine_type_unparsed" {
  assert {
    condition = (
      var.tpu_config == null ? true : (
        try(regex("^(?:ct|v)([0-9])", var.machine_type), "---") != "---"
      )
    )
    error_message = "WARNING: TPU machine type generation could not be parsed. TPU compatibility validation was skipped for the machine type."
  }
}

check "tpu_runtime_unparsed" {
  assert {
    condition = (
      var.tpu_config == null || var.tpu_config.runtime_version == null ? true : (
        try(coalesce(regex("(?:tpuv([0-9])|\\-v([0-9])\\-)", var.tpu_config.runtime_version)...), "---") != "---"
      )
    )
    error_message = "WARNING: TPU runtime version generation could not be parsed. TPU compatibility validation was skipped for the runtime."
  }
}

resource "google_tpu_v2_vm" "tpu" {
  provider         = google-beta
  count            = local.is_tpu_direct ? 1 : 0
  name             = var.name
  project          = local.project_id
  zone             = local.zone
  accelerator_type = local.tpu_accelerator_type
  runtime_version  = var.tpu_config.runtime_version
  network_config {
    network             = lookup(local.ctx.networks, var.network_interfaces[0].network, var.network_interfaces[0].network)
    subnetwork          = lookup(local.ctx.subnets, var.network_interfaces[0].subnetwork, var.network_interfaces[0].subnetwork)
    enable_external_ips = try(var.network_interfaces[0].nat, false)
  }
  scheduling_config {
    preemptible = var.scheduling_config.provisioning_model == "SPOT"
  }
  dynamic "service_account" {
    for_each = var.service_account == null ? [] : [""]
    content {
      email = local.service_account.email
      scope = local.service_account.scopes
    }
  }
  dynamic "data_disks" {
    for_each = local.attached_disks_ordered
    content {
      source_disk = (
        var.attached_disks[data_disks.value.key].source.attach != null
        ? var.attached_disks[data_disks.value.key].source.attach
        : data_disks.value.is_regional ? google_compute_region_disk.disks[data_disks.value.key].id : google_compute_disk.disks[data_disks.value.key].id
      )
      mode = var.attached_disks[data_disks.value.key].mode
    }
  }
  metadata = var.metadata
  labels   = var.labels
}

resource "google_tpu_v2_queued_resource" "tpu_queued" {
  provider = google-beta
  count    = local.is_tpu_queued ? 1 : 0
  name     = var.name
  project  = local.project_id
  zone     = local.zone
  tpu {
    node_spec {
      parent  = "projects/${local.project_id}/locations/${local.zone}"
      node_id = var.name
      node {
        accelerator_type = local.tpu_accelerator_type
        runtime_version  = var.tpu_config.runtime_version
        network_config {
          network             = lookup(local.ctx.networks, var.network_interfaces[0].network, var.network_interfaces[0].network)
          subnetwork          = lookup(local.ctx.subnets, var.network_interfaces[0].subnetwork, var.network_interfaces[0].subnetwork)
          enable_external_ips = try(var.network_interfaces[0].nat, false)
        }
      }
    }
  }
}
