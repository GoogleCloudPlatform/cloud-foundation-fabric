/**
 * Copyright 2019 Google LLC
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
  prefix      = var.prefix == "" ? "" : join("-", [var.prefix, lower(var.location), ""])
}

resource "google_storage_bucket" "buckets" {
  for_each           = toset(var.names)
  name               = "${local.prefix}${lower(each.key)}"
  project            = var.project_id
  location           = var.location
  storage_class      = var.storage_class
  force_destroy      = lookup(var.force_destroy, each.key, false)
  bucket_policy_only = lookup(var.bucket_policy_only, each.key, true)
  versioning {
    enabled = lookup(var.versioning, each.key, false)
  }
  labels = merge(var.labels, {
    location      = lower(var.location)
    name          = lower(each.key)
    storage_class = lower(var.storage_class)
  })
}

resource "google_storage_bucket_iam_binding" "bindings" {
  for_each = local.iam_keypairs
  bucket   = google_storage_bucket.buckets[each.value.name].name
  role     = each.value.role
  members = lookup(
    lookup(local.iam_members, each.value.name, {}), each.value.role, []
  )
}
