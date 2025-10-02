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
  # _off = {
  #   bucket = try(
  #     local.defaults.output_files.provider_pattern.storage_bucket, null
  #   )
  #   create = try(
  #     local.defaults.output_files.provider_pattern.storage_folders.create, null
  #   )
  #   create = try(
  #     local.defaults.output_files.provider_pattern.storage_folders.iam_assign, null
  #   )
  # }
  #   _of_folder_readers = [
  #     for v in lookup(local._of_folders, "iam_readers", []) :
  #     v if contains(local.of_providers_service_accounts, v)
  #   ]
  #   _of_folder_writers = [
  #     for v in lookup(local._of_folders, "iam_writers", []) :
  #     v if contains(local.of_providers_service_accounts, v)
  #   ]
  # }
}
# module "output-folders" {
#   source     = "../../../modules/gcs"
#   project_id = var.project_id
#   prefix     = var.prefix
#   name       = "my-bucket"
#   location   = "EU"
#   versioning = true
#   labels = {
#     cost-center = "devops"
#   }
# }