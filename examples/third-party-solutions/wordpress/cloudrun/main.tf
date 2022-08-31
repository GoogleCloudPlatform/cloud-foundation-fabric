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
  prefix = var.prefix == null ? "" : "${var.prefix}-"
  all_principals_iam = [
    for k in var.principals :
    "user:${k}"
  ]
  iam = {
    # CloudSQL
    "roles/cloudsql.admin"        = local.all_principals_iam
    "roles/cloudsql.client"       = local.all_principals_iam
    "roles/cloudsql.instanceUser" = local.all_principals_iam
    # common roles
    "roles/logging.admin"                  = local.all_principals_iam
    "roles/iam.serviceAccountUser"         = local.all_principals_iam
    "roles/iam.serviceAccountTokenCreator" = local.all_principals_iam
  }
  cloud_sql_conf = {
    database_version = "MYSQL_8_0"
    tier             = "db-g1-small"
    db               = "wp-mysql"
    user             = "admin"
    pass             = "password"
  }
  wp_user = "user"
}


module "project" { # either create a project or set up the given one
  source          = "../../../../modules/project"
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
    "vpcaccess.googleapis.com"
  ]
}

resource "random_password" "wp_password" {
  length = 8
}

module "cloud_run" { # create the Cloud Run service
  source     = "../../../../modules/cloud-run"
  project_id = module.project.project_id
  name       = "${local.prefix}cr-wordpress"
  region     = var.region

  containers = [{
    image = var.wordpress_image
    ports = [{
      name           = "http1"
      protocol       = null
      container_port = var.wordpress_port
    }]
    options = {
      command  = null
      args     = null
      env_from = null
      env = { # set up the database connection
        "APACHE_HTTP_PORT_NUMBER" : var.wordpress_port
        "WORDPRESS_DATABASE_HOST" : module.cloudsql.ip
        "WORDPRESS_DATABASE_NAME" : local.cloud_sql_conf.db
        "WORDPRESS_DATABASE_USER" : local.cloud_sql_conf.user
        "WORDPRESS_DATABASE_PASSWORD" : local.cloud_sql_conf.pass
        "WORDPRESS_USERNAME" : local.wp_user
        "WORDPRESS_PASSWORD" : random_password.wp_password.result
      }
    }
    resources     = null
    volume_mounts = null
  }]

  iam = {
    "roles/run.invoker" : [var.cloud_run_invoker]
  }

  revision_annotations = {
    autoscaling = {
      min_scale = 1
      max_scale = 2
    }
    # connect to CloudSQL
    cloudsql_instances  = [module.cloudsql.connection_name]
    vpcaccess_connector = null
    vpcaccess_egress    = "all-traffic" # allow all traffic
  }
  ingress_settings = "all"

  vpc_connector_create = { # create a VPC connector for the ClouSQL VPC
    ip_cidr_range = var.connector_cidr
    name          = "${local.prefix}wp-connector"
    vpc_self_link = module.vpc.self_link
  }
}


module "vpc" { # create a VPC for CloudSQL
  source     = "../../../../modules/net-vpc"
  project_id = module.project.project_id
  name       = "${local.prefix}sql-vpc"
  subnets = [
    {
      ip_cidr_range      = var.sql_vpc_cidr
      name               = "subnet"
      region             = var.region
      secondary_ip_range = {}
    }
  ]

  psa_config = { # Private Service Access
    ranges = {
      cloud-sql = var.psa_cidr
    }
    routes = null
  }
}


module "firewall" { # set up firewall for CloudSQL
  source       = "../../../../modules/net-vpc-firewall"
  project_id   = module.project.project_id
  network      = module.vpc.name
  admin_ranges = [var.sql_vpc_cidr]
}


module "cloudsql" { # Set up CloudSQL
  source           = "../../../../modules/cloudsql-instance"
  project_id       = module.project.project_id
  network          = module.vpc.self_link
  name             = "${local.prefix}mysql"
  region           = var.region
  database_version = local.cloud_sql_conf.database_version
  tier             = local.cloud_sql_conf.tier
  databases        = [local.cloud_sql_conf.db]
  users = {
    "${local.cloud_sql_conf.user}" = "${local.cloud_sql_conf.pass}"
  }
}