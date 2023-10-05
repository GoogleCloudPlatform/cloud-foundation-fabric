/**
 * Copyright 2023 Google LLC
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
  iam_roles = {
    data_eng = [
      "roles/owner"
    ]
    sql_robot = [
      "roles/compute.networkUser",
      "roles/storage.objectAdmin"
    ]
    sql_sa = [
      "roles/cloudsql.client",
      "roles/cloudsql.instanceUser"
    ]
  }
  shared_vpc_project = try(var.network_config.host_project, null)
  subnet = (
    local.use_shared_vpc
    ? var.network_config.subnet_self_link
    : values(module.vpc.0.subnet_self_links)[0]
  )
  use_shared_vpc = var.network_config != null
  vpc_self_link = (
    local.use_shared_vpc
    ? var.network_config.network_self_link
    : module.vpc.0.self_link
  )
}

module "project" {
  source          = "../../../modules/project"
  name            = var.project_id
  parent          = try(var.project_create.parent, null)
  billing_account = try(var.project_create.billing_account_id, null)
  project_create  = var.project_create != null
  prefix          = var.project_create == null ? null : var.prefix
  iam_bindings_additive = merge(
    var.data_eng_principal == null ? {} : {
      for r in local.iam_roles.data_eng : "data_eng-${r}" => {
        member = var.data_eng_principal
        role   = r
      }
    },
    {
      for r in local.iam_roles.sql_robot : "sql_robot-${r}" => {
        member = "serviceAccount:${module.project.service_accounts.robots.sql}"
        role   = r
      }
    },
    {
      for r in local.iam_roles.sql_sa : "sql_sa-${r}" => {
        member = module.service-account-sql.iam_email
        role   = r
      }
    }
  )
  services = [
    "cloudkms.googleapis.com",
    "compute.googleapis.com",
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
  shared_vpc_service_config = local.shared_vpc_project == null ? null : {
    attach       = true
    host_project = local.shared_vpc_project
  }
  service_encryption_key_ids = {
    compute = try(values(var.service_encryption_keys), [])
    sql     = try(values(var.service_encryption_keys), [])
    storage = try(values(var.service_encryption_keys), [])
  }
  service_config = {
    disable_on_destroy = false, disable_dependent_services = false
  }
}

module "vpc" {
  source     = "../../../modules/net-vpc"
  count      = local.use_shared_vpc ? 0 : 1
  project_id = module.project.project_id
  name       = "vpc"
  subnets = [
    {
      ip_cidr_range = "10.0.0.0/20"
      name          = "subnet"
      region        = var.regions.primary
    }
  ]
  psa_config = {
    ranges = { cloud-sql = var.sql_configuration.psa_range }
    routes = null
  }
}

module "firewall" {
  source     = "../../../modules/net-vpc-firewall"
  count      = local.use_shared_vpc ? 0 : 1
  project_id = module.project.project_id
  network    = module.vpc.0.name
  default_rules_config = {
    admin_ranges = ["10.0.0.0/20"]
  }
}

module "nat" {
  source         = "../../../modules/net-cloudnat"
  count          = local.use_shared_vpc ? 0 : 1
  project_id     = module.project.project_id
  region         = var.regions.primary
  name           = "${var.prefix}-default"
  router_network = module.vpc.0.name
}

module "gcs" {
  source         = "../../../modules/gcs"
  project_id     = module.project.project_id
  prefix         = var.prefix
  name           = "data"
  location       = var.regions.primary
  storage_class  = "REGIONAL"
  encryption_key = var.service_encryption_keys != null ? try(var.service_encryption_keys[var.regions.primary], null) : null
  force_destroy  = !var.deletion_protection
}
