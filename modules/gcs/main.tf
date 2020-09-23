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

locals {
  buckets = (
    local.has_buckets
    ? [for name in var.names : google_storage_bucket.buckets[name]]
    : []
  )
  # needed when destroying
  has_buckets = length(google_storage_bucket.buckets) > 0
  iam_pairs = var.iam_roles == null ? [] : flatten([
    for name, roles in var.iam_roles :
    [for role in roles : { name = name, role = role }]
  ])
  iam_keypairs = {
    for pair in local.iam_pairs :
    "${pair.name}-${pair.role}" => pair
  }
  iam_members = var.iam_members == null ? {} : var.iam_members
  prefix = (
    var.prefix == null || var.prefix == "" # keep "" for backward compatibility
    ? ""
    : join("-", [var.prefix, lower(var.location), ""])
  )
  kms_keys = {
    for name in var.names : name => lookup(var.encryption_keys, name, null)
  }
  retention_policy = {
    for name in var.names : name => lookup(var.retention_policies, name, null)
  }
  logging_config = {
    for name in var.names : name => lookup(var.logging_config, name, null)
  }
}

resource "google_storage_bucket" "buckets" {
  for_each           = toset(var.names)
  name               = "${local.prefix}${lower(each.key)}"
  project            = var.project_id
  location           = var.location
  storage_class      = var.storage_class
  force_destroy      = lookup(var.force_destroy, each.key, false)
  uniform_bucket_level_access = lookup(var.uniform_bucket_level_access, each.key, true)
  versioning {
    enabled = lookup(var.versioning, each.key, false)
  }
  labels = merge(var.labels, {
    location      = lower(var.location)
    name          = lower(each.key)
    storage_class = lower(var.storage_class)
  })

  dynamic encryption {
    for_each = local.kms_keys[each.key] == null ? [] : [""]

    content {
      default_kms_key_name = local.kms_keys[each.key]
    }
  }

  dynamic retention_policy {
    for_each = local.retention_policy[each.key] == null ? [] : [""]
    content {
      retention_period = local.retention_policy[each.key]["retention_period"]
      is_locked        = local.retention_policy[each.key]["is_locked"]
    }
  }

  dynamic logging {
    for_each = local.logging_config[each.key] == null ? [] : [""]
    content {
      log_bucket        = local.logging_config[each.key]["log_bucket"]
      log_object_prefix = local.logging_config[each.key]["log_object_prefix"]
    }
  }
}

resource "google_storage_bucket_iam_binding" "bindings" {
  for_each = local.iam_keypairs
  bucket   = google_storage_bucket.buckets[each.value.name].name
  role     = each.value.role
  members = lookup(
    lookup(local.iam_members, each.value.name, {}), each.value.role, []
  )
}
