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
    "roles/cloudsql.admin" = local.data_eng_principals_iam
    "roles/cloudsql.client" = concat(
      local.data_eng_principals_iam,
      [module.service-account-sql.iam_email]
    )
    "roles/cloudsql.instanceUser" = concat(
      local.data_eng_principals_iam,
      [module.service-account-sql.iam_email]
    )
    # compute engeneering 
    "roles/compute.instanceAdmin.v1"   = local.data_eng_principals_iam
    "roles/compute.osLogin"            = local.data_eng_principals_iam
    "roles/compute.viewer"             = local.data_eng_principals_iam
    "roles/iap.tunnelResourceAccessor" = local.data_eng_principals_iam
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
    "iap.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "networkmanagement.googleapis.com",
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
  subnets = [
    {
      ip_cidr_range      = "10.0.0.0/20"
      name               = "subnet"
      region             = var.regions.primary
      secondary_ip_range = {}
    }
  ]

  psa_config = {
    ranges = { cloud-sql = var.sql_configuration.psa_range }
    routes = null
  }
}

module "firewall" {
  source       = "../../../modules/net-vpc-firewall"
  project_id   = module.project.project_id
  network      = module.vpc.name
  admin_ranges = ["10.0.0.0/20"]
}

module "nat" {
  source         = "../../../modules/net-cloudnat"
  project_id     = module.project.project_id
  region         = var.regions.primary
  name           = "${var.prefix}-default"
  router_network = module.vpc.name
}
