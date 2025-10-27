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
  of_pf_create = local.of_p.bucket != null && local.of_p.folders_create
}

module "output-pattern-folders" {
  source        = "../../../modules/gcs"
  count         = local.of_pf_create ? 1 : 0
  bucket_create = false
  name = lookup(
    local.of_storage_buckets, local.of_p.bucket, local.of_p.bucket
  )
  managed_folders = {
    for k, v in local.of_p.projects :
    "${k}/" => {
      iam_bindings_additive = merge(
        v.ro == null ? {} : {
          automation_ro = {
            member = "serviceAccount:${v.ro}"
            role   = "roles/storage.objectViewer"
          }
        },
        v.rw == null ? {} : {
          automation_rw = {
            member = "serviceAccount:${v.rw}"
            role   = "roles/storage.objectAdmin"
          }
        }
      )
    }
  }
}