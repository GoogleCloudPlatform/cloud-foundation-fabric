/**
 * Copyright 2024 Google LLC
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
  _region = join("-", slice(split("-", local.zone), 0, 2))
  advanced_mf = anytrue([
    for k, v in var.machine_features_config : v != null
  ])
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local.ctx_p}${k}:${kk}" => vv
    }
  }
  ctx_kms_keys = merge(local.ctx.kms_keys, {
    for k, v in google_kms_key_handle.default :
    "$kms_keys:autokeys/${k}" => v.kms_key
  })
  ctx_p = "$"
  gpu   = var.gpu != null
  on_host_maintenance = coalesce(
    var.scheduling_config.on_host_maintenance,
    (
      var.scheduling_config.provisioning_model == "SPOT" ||
      var.confidential_compute != null ||
      local.gpu
    ) ? "TERMINATE" : "MIGRATE"
  )
  project_id = lookup(local.ctx.project_ids, var.project_id, var.project_id)
  region     = lookup(local.ctx.locations, local._region, local._region)
  service_account = var.service_account == null ? null : {
    email = (var.service_account.auto_create
      ? google_service_account.service_account[0].email
      : try(
        local.ctx.iam_principals[var.service_account.email],
        var.service_account.email
      )
    )
    scopes = (
      var.service_account.scopes != null ? var.service_account.scopes : (
        var.service_account.email == null && !var.service_account.auto_create
        # default scopes for Compute default SA
        ? [
          "https://www.googleapis.com/auth/devstorage.read_only",
          "https://www.googleapis.com/auth/logging.write",
          "https://www.googleapis.com/auth/monitoring.write"
        ]
        # default scopes for own SA
        : [
          "https://www.googleapis.com/auth/cloud-platform",
          "https://www.googleapis.com/auth/userinfo.email"
        ]
      )
    )
  }
  termination_action = (
    var.scheduling_config.provisioning_model == "SPOT" || var.scheduling_config.max_run_duration != null
    ? coalesce(var.scheduling_config.termination_action, "STOP")
    : null
  )
  zone = lookup(local.ctx.locations, var.zone, var.zone)
}

resource "google_kms_key_handle" "default" {
  for_each = var.kms_autokeys
  project  = local.project_id
  name     = each.key
  location = coalesce(
    try(local.ctx.locations[each.value.location], null),
    each.value.location,
    local.region
  )
  resource_type_selector = each.value.resource_type_selector
}

resource "google_compute_instance_iam_binding" "default" {
  project       = local.project_id
  for_each      = var.iam
  zone          = local.zone
  instance_name = var.name
  role          = lookup(local.ctx.custom_roles, each.key, each.key)
  members = [
    for m in each.value : lookup(local.ctx.iam_principals, m, m)
  ]
  depends_on = [google_compute_instance.default]
}

resource "google_compute_instance_group" "unmanaged" {
  count   = try(var.group.membership, null) == null && var.group != null && !local.is_template ? 1 : 0
  project = local.project_id
  network = (
    length(var.network_interfaces) > 0
    ? var.network_interfaces[0].network
    : ""
  )
  zone        = local.zone
  name        = var.name
  description = var.description
  instances   = [google_compute_instance.default[0].self_link]
  dynamic "named_port" {
    for_each = var.group.named_ports != null ? var.group.named_ports : {}
    iterator = config
    content {
      name = config.key
      port = config.value
    }
  }
}

resource "google_compute_instance_group_membership" "unmanaged" {
  count          = try(var.group.membership, null) != null && !local.is_template ? 1 : 0
  project        = local.project_id
  zone           = local.zone
  instance       = google_compute_instance.default[0].self_link
  instance_group = var.group.membership
}

resource "google_service_account" "service_account" {
  count        = try(var.service_account.auto_create, null) == true ? 1 : 0
  project      = local.project_id
  account_id   = "tf-vm-${var.name}"
  display_name = "Terraform VM ${var.name}."
}
