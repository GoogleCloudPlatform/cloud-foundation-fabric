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
  cloudsql_conf = {
    database_version = "MYSQL_8_0"
    tier             = "db-g1-small"
    db               = "wp-mysql"
    user             = "admin"
  }
  iam_roles = [
    "roles/cloudsql.admin",
    "roles/cloudsql.client",
    "roles/cloudsql.instanceUser",
    "roles/logging.admin",
    "roles/iam.serviceAccountUser",
    "roles/iam.serviceAccountTokenCreator"
  ]
  connector = var.connector == null ? google_vpc_access_connector.connector[0].self_link : var.connector
  wp_user   = "user"
  wp_pass   = var.wordpress_password == null ? random_password.wp_password.result : var.wordpress_password
}

resource "random_password" "wp_password" {
  length = 8
}

module "project" {
  source          = "../../../../modules/project"
  name            = var.project_id
  parent          = try(var.project_create.parent, null)
  billing_account = try(var.project_create.billing_account_id, null)
  project_create  = var.project_create != null
  prefix          = var.project_create == null ? null : var.prefix
  iam = (
    var.project_create != true || var.admin_principal == null
    ? {}
    : { for r in local.iam_roles : r => [var.admin_principal] }
  )
  iam_bindings_additive = (
    var.project_create == true || var.admin_principal == null
    ? {}
    : { for r in local.iam_roles : r => {
      member = var.admin_principal
      role   = r
    } }
  )
  services = [
    "run.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "sqladmin.googleapis.com",
    "sql-component.googleapis.com",
    "vpcaccess.googleapis.com",
    "servicenetworking.googleapis.com"
  ]
}

module "cloud_run" {
  source     = "../../../../modules/cloud-run"
  project_id = module.project.project_id
  name       = "${var.prefix}-cr-wordpress"
  region     = var.region
  containers = {
    wp = {
      image = var.wordpress_image
      ports = {
        http = { container_port = var.wordpress_port }
      }
      env = {
        APACHE_HTTP_PORT_NUMBER = var.wordpress_port
        WORDPRESS_DATABASE_HOST = module.cloudsql.ip
        WORDPRESS_DATABASE_NAME = local.cloudsql_conf.db
        WORDPRESS_DATABASE_USER = local.cloudsql_conf.user
        WORDPRESS_DATABASE_PASSWORD = (
          var.cloudsql_password == null
          ? module.cloudsql.user_passwords[local.cloudsql_conf.user]
          : var.cloudsql_password
        )
        WORDPRESS_USERNAME = local.wp_user
        WORDPRESS_PASSWORD = local.wp_pass
      }
    }
  }
  iam = {
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
    vpcaccess_connector = local.connector
    vpcaccess_egress    = "all-traffic"
  }
  ingress_settings = "all"
}
