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
  of_buckets = {
    for k, v in module.factory.storage_buckets :
    "$storage_buckets:${k}" => v
  }
  of_service_accounts = {
    for k, v in module.factory.service_accounts :
    "$iam_principals:service_accounts/${k}" => v
  }
  of_path = (
    local.output_files.local_path == null
    ? null
    : pathexpand(local.output_files.local_path)
  )
  of_template = file("assets/providers.tf")
}


resource "local_file" "providers" {
  for_each        = local.of_path == null ? {} : local.output_files.providers
  file_permission = "0644"
  filename        = "${local.of_path}/providers/${each.key}-providers.tf"
  content = templatestring(local.of_template, {
    bucket = lookup(
      local.of_buckets, each.value.bucket, each.value.bucket
    )
    service_account = lookup(
      local.of_service_accounts, each.value.service_account, each.value.service_account
    )
  })
}

resource "google_storage_bucket_object" "providers" {
  for_each = local.output_files.storage_bucket == null ? {} : local.output_files.providers
  bucket = lookup(
    local.of_buckets,
    local.output_files.storage_bucket,
    local.output_files.storage_bucket
  )
  name = "providers/${each.key}-providers.tf"
  content = templatestring(local.of_template, {
    bucket = lookup(
      local.of_buckets, each.value.bucket, each.value.bucket
    )
    service_account = lookup(
      local.of_service_accounts, each.value.service_account, each.value.service_account
    )
  })
}
