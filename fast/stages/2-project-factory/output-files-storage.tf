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

# locals {
#   _of_folders_bucket = try(
#     local.defaults.output_files.provider_pattern.storage.bucket, null
#   )
#   _of_folders = try(
#     local.defaults.output_files.provider_pattern.storage.folders, {}
#   )
#   of_folders_bucket = local._of_folders_bucket == null ? null : lookup(
#     local.of_storage_buckets, local._of_folders_bucket, local._of_folders_bucket
#   )
#   of_folders_create = (
#     local.of_folders_bucket != null &&
#     lookup(local._of_folders, "create", null) == true
#   )
#   _of_folder_readers = [
#     for v in lookup(local._of_folders, "iam_readers", []) :
#     v if contains(local.of_providers_service_accounts, v)
#   ]
#   _of_folder_writers = [
#     for v in lookup(local._of_folders, "iam_writers", []) :
#     v if contains(local.of_providers_service_accounts, v)
#   ]
# }

# resource "google_storage_managed_folder" "folder" {
#   for_each = toset(local.of_folders_create ? local.of_providers_projects : [])
#   bucket   = local.of_folders_bucket
#   name     = "${local.of_prefix}/${each.key}/"
# }