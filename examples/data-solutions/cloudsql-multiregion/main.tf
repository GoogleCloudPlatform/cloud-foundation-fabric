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
  data_eng_principals_iam = [
    for k in var.data_eng_principals :
    "user:${k}"
  ]

  iam = {
    # GCS roles
    "roles/storage.objectAdmin" = [
      "serviceAccount:${module.project.service_accounts.robots.sql}",
      module.service-account-gcs.iam_email,
    ]
    # CloudSQL 
    "roles/cloudsql.instanceUser" = concat(
      local.data_eng_principals_iam,
      [module.service-account-sql.iam_email]
    )
    # common roles
    "roles/logging.admin" = local.data_eng_principals_iam
    "roles/iam.serviceAccountUser" = concat(
      local.data_eng_principals_iam
    )
    "roles/iam.serviceAccountTokenCreator" = concat(
      local.data_eng_principals_iam
    )
    # network roles
    "roles/compute.networkUser" = [
      "serviceAccount:${module.project.service_accounts.robots.sql}"
    ]
  }

  # # VPC / Shared VPC variables
  # network_subnet_selflink = try(
  #   module.vpc[0].subnets["${var.region}/subnet"].self_link,
  #   var.network_config.subnet_self_link
  # )
  # shared_vpc_bindings = {
  #   "roles/compute.networkUser" = [
  #     "robot-df", "sa-df-worker"
  #   ]
  # }
  # # reassemble in a format suitable for for_each
  # shared_vpc_bindings_map = {
  #   for binding in flatten([
  #     for role, members in local.shared_vpc_bindings : [
  #       for member in members : { role = role, member = member }
  #     ]
  #   ]) : "${binding.role}-${binding.member}" => binding
  # }
  # shared_vpc_project = try(var.network_config.host_project, null)
  # shared_vpc_role_members = {
  #   robot-df     = "serviceAccount:${module.project.service_accounts.robots.dataflow}"
  #   sa-df-worker = module.service-account-df.iam_email
  # }
  # use_shared_vpc = var.network_config != null
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
    "cloudkms.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "sql-component.googleapis.com",
    "storage.googleapis.com",
    "storage-component.googleapis.com",
  ]
  service_config = {
    disable_on_destroy = false, disable_dependent_services = false
  }
}

module "vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.project.project_id
  name       = "vpc"
  psa_config = {
    ranges = { cloud-sql = var.sql_configuration.psa_range }
    routes = null
  }
}

module "db" {
  source              = "../../../modules/cloudsql-instance"
  project_id          = module.project.project_id
  availability_type   = var.sql_configuration.availability_type
  encryption_key_name = var.cmek_encryption ? module.kms[var.regions.primary].keys.key.id : null
  network             = module.vpc.self_link
  name                = "${var.prefix}-db-04"
  region              = var.regions.primary
  database_version    = var.sql_configuration.database_version
  tier                = var.sql_configuration.tier
  flags = {
    "cloudsql.iam_authentication" = "on"
  }
  replicas = {
    for k, v in var.regions :
    k => {
      region              = v,
      encryption_key_name = var.cmek_encryption ? module.kms[v].keys.key.id : null
    } if k != "primary"
  }
  databases = var.postgres_databases
  users = {
    postgres = var.postgres_user_password
  }
}

resource "google_sql_user" "users" {
  for_each = toset(var.data_eng_principals)
  project  = module.project.project_id
  name     = each.value
  instance = module.db.name
  type     = "CLOUD_IAM_USER"
}

resource "google_sql_user" "service-account" {
  for_each = toset(var.data_eng_principals)
  project  = module.project.project_id
  # Omit the .gserviceaccount.com suffix in the email
  name     = regex("(.+)(gserviceaccount)", module.service-account-sql.email)[0]
  instance = module.db.name
  type     = "CLOUD_IAM_SERVICE_ACCOUNT"
}

module "gcs" {
  source         = "../../../modules/gcs"
  project_id     = module.project.project_id
  prefix         = var.prefix
  name           = "data"
  location       = var.regions.primary
  storage_class  = "REGIONAL"
  encryption_key = var.cmek_encryption ? module.kms[var.regions.primary].keys["key"].id : null
  force_destroy  = true
}

module "service-account-gcs" {
  source     = "../../../modules/iam-service-account"
  project_id = module.project.project_id
  name       = "${var.prefix}-gcs"
}

module "service-account-sql" {
  source     = "../../../modules/iam-service-account"
  project_id = module.project.project_id
  name       = "${var.prefix}-sql"
}
