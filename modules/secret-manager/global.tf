/**
 * Copyright 2025 Google LLC
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
  _tag_template_global = (
    "//secretmanager.googleapis.com/projects/%s/secrets/%s"
  )
}

resource "google_secret_manager_secret" "default" {
  for_each            = { for k, v in var.secrets : k => v if v.location == null }
  project             = local.project_id
  secret_id           = each.key
  labels              = each.value.labels
  annotations         = each.value.annotations
  version_aliases     = try(each.value.version_config.aliases, null)
  version_destroy_ttl = try(each.value.version_config.destroy_ttl, null)
  expire_time         = try(each.value.expiration_config.time, null)
  ttl                 = try(each.value.expiration_config.ttl, null)
  tags = {
    for k, v in each.value.tags :
    lookup(local.ctx.tag_keys, k, k) => lookup(local.ctx.tag_values, v, v)
  }
  deletion_protection = each.value.deletion_protection
  dynamic "replication" {
    for_each = try(each.value.global_replica_locations, null) == null ? [""] : []
    content {
      auto {
        dynamic "customer_managed_encryption" {
          for_each = each.value.kms_key == null ? [] : [""]
          content {
            kms_key_name = lookup(
              local.ctx.kms_keys, each.value.kms_key, each.value.kms_key
            )
          }
        }
      }
    }
  }
  dynamic "replication" {
    for_each = try(each.value.global_replica_locations, null) != null ? [""] : []
    content {
      user_managed {
        dynamic "replicas" {
          for_each = each.value.global_replica_locations
          content {
            location = lookup(local.ctx.locations, replicas.key, replicas.key)
            dynamic "customer_managed_encryption" {
              for_each = replicas.value == null ? [] : [""]
              content {
                kms_key_name = lookup(
                  local.ctx.kms_keys, replicas.value, replicas.value
                )
              }
            }
          }
        }
      }
    }
  }
  # dynamic "rotation" {
  #   for_each = try(each.value.rotation_config, null) == null ? [] : [""]
  #   content {
  #     next_rotation_time = each.value.rotation_config.next_time
  #     rotation_period    = each.value.rotation_config.period
  #   }
  # }
  # topics
  lifecycle {
    ignore_changes = [
      rotation[0].next_rotation_time
    ]
  }
}

resource "google_secret_manager_secret_version" "default" {
  for_each = {
    for v in local.versions :
    "${v.secret}/${v.version}" => v if v.location == null
  }
  secret          = google_secret_manager_secret.default[each.value.secret].id
  deletion_policy = each.value.deletion_policy
  enabled         = each.value.enabled
  is_secret_data_base64 = try(
    each.value.data_config.is_base64, null
  )
  secret_data_wo_version = try(
    each.value.data_config.write_only_version, null
  )
  secret_data = (
    try(each.value.data_config.write_only_version, null) != null
    ? null
    : (
      try(each.value.data_config.is_file, null) == true
      ? file(each.value.data)
      : each.value.data
    )
  )
  secret_data_wo = (
    try(each.value.data_config.write_only_version, null) == null
    ? null
    : (
      try(each.value.data_config.is_file, null) == true
      ? file(each.value.data)
      : each.value.data
    )
  )
}

resource "google_tags_tag_binding" "binding" {
  for_each = { for k, v in local.tag_bindings : k => v if v.location == null }
  parent = format(
    local._tag_template_global,
    local.tag_project,
    google_secret_manager_secret.default[each.value.secret].secret_id
  )
  tag_value = lookup(local.ctx.tag_values, each.value.tag, each.value.tag)
}
