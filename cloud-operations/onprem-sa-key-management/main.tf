/**
 * Copyright 2021 Google LLC
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


module "project" {
  source         = "../../modules/project"
  name           = var.project_id
  project_create = var.project_create
}

module "onprem-data-uploader" {
  source     = "../../modules/iam-service-account"
  project_id = module.project.project_id
  name       = "onprem-data-uploader"
  iam_project_roles = {
    (module.project.project_id) = [
      "roles/bigquery.dataOwner",
      "roles/bigquery.jobUser",
      "roles/storage.objectAdmin"
    ]
  }
  public_keys_directory = "public-keys/data-uploader/"
}

module "onprem-prisma-security" {
  source     = "../../modules/iam-service-account"
  project_id = module.project.project_id
  name       = "onprem-prisma-security"
  iam_project_roles = {
    (module.project.project_id) = [
      "roles/iam.securityReviewer"
    ]
  }
  public_keys_directory = "public-keys/prisma-security/"
}
