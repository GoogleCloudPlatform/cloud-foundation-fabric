/**
 * Copyright 2022 Google LLC
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
  all_principals_iam = [
    for k in var.principals :
    "user:${k}"
  ]
  iam = {
    # GCS roles
    "roles/storage.objectAdmin" = [
      module.service-account-gcs.iam_email,
    ]
    # CloudSQL
    "roles/cloudsql.admin" = local.all_principals_iam
    "roles/cloudsql.client" = concat(
      local.all_principals_iam,
      [module.service-account-sql.iam_email]
    )
    "roles/cloudsql.instanceUser" = concat(
      local.all_principals_iam,
      [module.service-account-sql.iam_email]
    )
    # common roles
    "roles/logging.admin" = local.all_principals_iam
    "roles/iam.serviceAccountUser" = local.all_principals_iam
    "roles/iam.serviceAccountTokenCreator" = local.all_principals_iam
  }
}

module "project" {
  source          = "../../../modules/project"
  name            = var.project_id
  parent          = try(var.project_create.parent, null)
  billing_account = try(var.project_create.billing_account_id, null)
  project_create  = var.project_create != null
  prefix          = var.project_create == null ? null : var.prefix
  iam             = var.project_create != null ? local.iam : {}
  iam_additive    = var.project_create == null ? local.iam : {}
  services = [
    "run.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "sqladmin.googleapis.com",
    "sql-component.googleapis.com",
    "storage.googleapis.com",
    "storage-component.googleapis.com",
  ]
  service_config = {
    disable_on_destroy = false, disable_dependent_services = false
  }
}