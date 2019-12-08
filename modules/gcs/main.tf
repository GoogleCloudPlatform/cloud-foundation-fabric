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
  prefix       = var.prefix == "" ? "" : join("-", list(var.prefix, lower(var.location), ""))
  names        = toset(var.names)
  buckets_list = [for name in var.names : google_storage_bucket.buckets[name]]
}

resource "google_storage_bucket" "buckets" {
  for_each           = local.names
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
    name = "${local.prefix}${lower(each.key)}"
  })
}

resource "google_storage_bucket_iam_binding" "object_admins" {
  for_each = var.set_object_admin_roles ? local.names : toset([])
  bucket   = google_storage_bucket.buckets[each.key].name
  role     = "roles/storage.objectAdmin"
  members = compact(concat(
    var.object_admins,
    split(",", lookup(var.bucket_object_admins, each.key, ""))
  ))
}

resource "google_storage_bucket_iam_binding" "creators" {
  for_each = var.set_creator_roles ? local.names : toset([])
  bucket   = google_storage_bucket.buckets[each.key].name
  role     = "roles/storage.objectCreator"
  members = compact(concat(
    var.creators,
    split(",", lookup(var.bucket_creators, each.key, ""))
  ))
}

resource "google_storage_bucket_iam_binding" "viewers" {
  for_each = var.set_viewer_roles ? local.names : toset([])
  bucket   = google_storage_bucket.buckets[each.key].name
  role     = "roles/storage.objectViewer"
  members = compact(concat(
    var.viewers,
    split(",", lookup(var.bucket_viewers, each.key, ""))
  ))
}

resource "google_storage_bucket_iam_binding" "hmackey_admins" {
  for_each = var.set_hmackey_admin_roles ? local.names : toset([])
  bucket   = google_storage_bucket.buckets[each.key].name
  role     = "roles/storage.hmacKeyAdmin"
  members = compact(concat(
    var.hmackey_admins,
    split(",", lookup(var.bucket_hmackey_admins, each.key, ""))
  ))
}

resource "google_storage_bucket_iam_binding" "admins" {
  for_each = var.set_admin_roles ? local.names : toset([])
  bucket   = google_storage_bucket.buckets[each.key].name
  role     = "roles/storage.admin"
  members = compact(concat(
    var.admins,
    split(",", lookup(var.bucket_admins, each.key, ""))
  ))
}
