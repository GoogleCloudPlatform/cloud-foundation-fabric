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
  bundle_type = (
    startswith(var.bundle_config.path, "gs://")
    ? "gcs"
    : (
      try(fileexists(pathexpand(var.bundle_config.path)), null) != null &&
      endswith(var.bundle_config.path, ".zip")
      ? "local-file"
      : "local-folder"
    )
  )
}

resource "google_storage_bucket" "bucket" {
  count                       = var.bucket_config == null ? 0 : 1
  project                     = var.project_id
  name                        = "${local.prefix}${var.bucket_name}"
  uniform_bucket_level_access = true
  location = (
    var.bucket_config.location == null
    ? var.region
    : var.bucket_config.location
  )
  labels = var.labels
  dynamic "lifecycle_rule" {
    for_each = var.bucket_config.lifecycle_delete_age_days == null ? [] : [""]
    content {
      action { type = "Delete" }
      condition {
        age        = var.bucket_config.lifecycle_delete_age_days
        with_state = "ARCHIVED"
      }
    }
  }
  dynamic "versioning" {
    for_each = var.bucket_config.lifecycle_delete_age_days == null ? [] : [""]
    content {
      enabled = true
    }
  }
  force_destroy = var.bucket_config.force_destroy
}

# compress bundle in a zip archive if it's a folder

data "archive_file" "bundle" {
  count      = local.bundle_type == "local-folder" ? 1 : 0
  type       = "zip"
  source_dir = pathexpand(var.bundle_config.path)
  output_path = (
    var.bundle_config.folder_options.archive_path != null
    ? pathexpand(var.bundle_config.folder_options.archive_path)
    : "/tmp/bundle-${var.project_id}-${var.name}.zip"
  )
  output_file_mode = "0644"
  excludes         = var.bundle_config.folder_options.excludes
}

# upload to GCS

resource "google_storage_bucket_object" "bundle" {
  count = local.bundle_type != "gcs" ? 1 : 0
  name = try(
    "bundle-${data.archive_file.bundle[0].output_md5}.zip",
    basename(var.bundle_config.path)
  )
  bucket = local.bucket
  source = try(
    data.archive_file.bundle[0].output_path,
    pathexpand(var.bundle_config.path)
  )
}
