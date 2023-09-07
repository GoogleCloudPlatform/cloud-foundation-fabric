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
  cloudsql_conf = {
    database_version = "MYSQL_8_0"
    tier             = "db-g1-small"
    db               = "phpipam"
    user             = "admin"
  }
  connector = var.connector == null ? module.cloud_run.vpc_connector : var.connector
  domain = (
    var.custom_domain != null ? var.custom_domain : (
      var.phpipam_exposure == "EXTERNAL" ?
    "${module.addresses.0.global_addresses["phpipam"].address}.nip.io" : "phpipam.internal")
  )
  iam = {
    # CloudSQL
    "roles/cloudsql.admin"        = var.admin_principals
    "roles/cloudsql.client"       = var.admin_principals
    "roles/cloudsql.instanceUser" = var.admin_principals
    # common roles
    "roles/logging.admin"                  = var.admin_principals
    "roles/iam.serviceAccountUser"         = var.admin_principals
    "roles/iam.serviceAccountTokenCreator" = var.admin_principals
  }
  network          = var.vpc_config == null ? module.vpc.0.self_link : var.vpc_config.network
  phpipam_password = var.phpipam_password == null ? random_password.phpipam_password.result : var.phpipam_password
  subnetwork       = var.vpc_config == null ? module.vpc.0.subnet_self_links["${var.region}/ilb"] : var.vpc_config.subnetwork
}


# either create a project or set up the given one
module "project" {
  source          = "../../../modules/project"
  billing_account = try(var.project_create.billing_account_id, null)
  iam             = var.project_create != null ? local.iam : {}
  name            = var.project_id
  parent          = try(var.project_create.parent, null)
  prefix          = var.project_create == null ? null : var.prefix
  project_create  = var.project_create != null
  services = [
    "iap.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "run.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "sql-component.googleapis.com",
    "vpcaccess.googleapis.com"
  ]
}


# create a VPC for CloudSQL and ILB
module "vpc" {
  source     = "../../../modules/net-vpc"
  count      = var.vpc_config == null ? 1 : 0
  project_id = module.project.project_id
  name       = "${var.prefix}-sql-vpc"

  psa_config = {
    ranges = {
      cloud-sql = var.ip_ranges.psa
    }
  }
  subnets = [
    {
      ip_cidr_range = var.ip_ranges.ilb
      name          = "ilb"
      region        = var.region
    }
  ]
}

resource "random_password" "phpipam_password" {
  length = 8
}

# create the Cloud Run service
module "cloud_run" {
  source           = "../../../modules/cloud-run"
  project_id       = module.project.project_id
  name             = "${var.prefix}-cr-phpipam"
  prefix           = var.prefix
  ingress_settings = "all"
  region           = var.region

  containers = {
    phpipam = {
      image = var.phpipam_config.image
      ports = {
        http = {
          name           = "http1"
          protocol       = null
          container_port = var.phpipam_config.port
        }
      }
      env_from = null
      # set up the database connection
      env = {
        "TZ"                 = "Europe/Rome"
        "IPAM_DATABASE_HOST" = module.cloudsql.ip
        "IPAM_DATABASE_USER" = local.cloudsql_conf.user
        "IPAM_DATABASE_PASS" = var.cloudsql_password == null ? module.cloudsql.user_passwords[local.cloudsql_conf.user] : var.cloudsql_password
        "IPAM_DATABASE_NAME" = local.cloudsql_conf.db
        "IPAM_DATABASE_PORT" = "3306"
      }
    }
  }
  iam = local.glb_create && var.iap.enabled ? {
    "roles/run.invoker" : ["serviceAccount:${local.iap_sa_email}"]
    } : {
    "roles/run.invoker" : [var.cloud_run_invoker]
  }
  revision_annotations = {
    autoscaling = {
      min_scale = 1
      max_scale = 2
    }
    # connect to CloudSQL
    cloudsql_instances = [module.cloudsql.connection_name]
    # allow all traffic
    vpcaccess_egress    = "private-ranges-only"
    vpcaccess_connector = local.connector
  }
  vpc_connector_create = var.create_connector ? {
    ip_cidr_range = var.ip_ranges.connector
    vpc_self_link = local.network
  } : null
}
