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
    "roles/cloudsql.admin" = local.all_principals_iam
    "roles/cloudsql.client" = concat(
      local.all_principals_iam,
      #[module.service-account-sql.iam_email]
    )
    "roles/cloudsql.instanceUser" = concat(
      local.all_principals_iam,
      #[module.service-account-sql.iam_email]
    )
    # common roles
    "roles/logging.admin" = local.all_principals_iam
    "roles/iam.serviceAccountUser" = local.all_principals_iam
    "roles/iam.serviceAccountTokenCreator" = local.all_principals_iam
  }
  cloud_sql_conf = {
    availability_type = "ZONAL"
    database_version  = "MYSQL_8_0"
    psa_range         = "10.60.0.0/16"
    tier              = "db-g1-small"
    db                = "wp-mysql"
    user              = "admin"
    pass              = "password" # TODO: var
  }
  sql_vpc_cidr = "10.0.0.0/20"
  connector_cidr = "10.8.0.0/28" # !!!
}

module "project" {
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
    #"storage.googleapis.com",
    #"storage-component.googleapis.com",
    "vpcaccess.googleapis.com"
  ]
#  service_config = {
#    disable_on_destroy = false,
#    disable_dependent_services = false
#  }
}

module "cloud_run" {
  source     = "../../../../modules/cloud-run"
  project_id = module.project.project_id
  name     = "${local.prefix}cr-wordpress"
  region = var.region
  cloudsql_instances = module.cloudsql.connection_name
  vpc_connector = {
    create          = true
    name            = "${local.prefix}wp-connector"
    egress_settings = "all-traffic"
  }
  vpc_connector_config = {
    network       = module.vpc.self_link
    ip_cidr_range = local.connector_cidr
  }
#        "run.googleapis.com/ingress" = "internal-and-cloud-load-balancing"

  containers = [{
    image = var.wordpress_image
    ports = [{ # TODO https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_service
      name           = "http1"
      protocol       = "TCP"
      container_port = 80
    }]
    options = {
      command  = null
      args     = null
      env_from = null
      env      = {
        "DB_HOST"        : module.cloudsql.ip
        "DB_USER"        : local.cloud_sql_conf.user
        "DB_PASSWORD"    : local.cloud_sql_conf.pass
        "DB_NAME"        : local.cloud_sql_conf.db
        # "WORDPRESS_DEBUG": "1"
      }
    }
    resources = null
    volume_mounts = null
  }]

  iam = {
    "roles/run.invoker": [var.cloud_run_invoker]
  }
}


# tftest modules=1 resources=1

/*
# Grant Cloud Run usage rights to someone who is authorized to access the end-point
resource "google_cloud_run_service_iam_member" "cloud_run_iam_member" {
  project  = module.project.project_id
  location = google_cloud_run_service.cloud_run.location
  service  = google_cloud_run_service.cloud_run.name

  role = "roles/run.invoker"

  member = var.cloud_run_invoker
}
*/

module "vpc" {
  source     = "../../../../modules/net-vpc"
  project_id = module.project.project_id
  name       = "${local.prefix}sql-vpc"
  subnets = [
    {
      ip_cidr_range      = local.sql_vpc_cidr
      name               = "subnet"
      region             = var.region
      secondary_ip_range = {}
    }
  ]

  psa_config = {
    ranges = { cloud-sql = local.cloud_sql_conf.psa_range }
    routes = null
  }
}

module "firewall" {
  source       = "../../../../modules/net-vpc-firewall"
  project_id   = module.project.project_id
  network      = module.vpc.name
  admin_ranges = [local.sql_vpc_cidr]
}

module "nat" {
  source         = "../../../../modules/net-cloudnat"
  project_id     = module.project.project_id
  region         = var.region
  name           = "${local.prefix}nat"
  router_network = module.vpc.name
}

module "cloudsql" {
  source              = "../../../../modules/cloudsql-instance"
  project_id          = module.project.project_id
#  availability_type   = local.cloud_sql_conf.availability_type
  network             = module.vpc.self_link
  name                = "${local.prefix}mysql"
  region              = var.region
  database_version    = local.cloud_sql_conf.database_version
  tier                = local.cloud_sql_conf.tier
  databases           = [local.cloud_sql_conf.db]
  users = {
      "${local.cloud_sql_conf.user}" = "${local.cloud_sql_conf.pass}"
  }
#  authorized_networks = {
#    internet = "0.0.0.0/0"
#  }
}

/*
resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = module.vpc.self_link
  #network       = data.google_compute_network.default.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = module.vpc.self_link
  #network                 = data.google_compute_network.default.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}
*/

# ------------------------------------------------------------
/*
resource "google_compute_global_address" "default" {
  name = "${var.wordpress_project_name}-address"
}

# #OPTIONAL LB START

#or use your own cert here
#certificate can take up to 24h to provision
resource "google_compute_managed_ssl_certificate" "default" {
  name = "${var.wordpress_project_name}-cert"
  managed {
    domains = ["nip.io"]#tovars
  }
}


resource "google_compute_region_network_endpoint_group" "cloudrun_neg" {
  name                  = "${var.wordpress_project_name}-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = google_cloud_run_service.cloud_run.name
  }
}

module "lb-http" {
  source            = "GoogleCloudPlatform/lb-http/google//modules/serverless_negs"
  project = var.project

  name              = "${var.wordpress_project_name}-lb"

  managed_ssl_certificate_domains = ["nip.io"]
  ssl                             = true
  https_redirect                  = true

  backends = {
    default = {
      groups = [
        {
          group = google_compute_region_network_endpoint_group.cloudrun_neg.id
        }
      ]

      enable_cdn = false

      log_config = {
        enable      = false
        sample_rate = 0.0
      }

      iap_config = {
        enable               = false
        oauth2_client_id     = null
        oauth2_client_secret = null
      }

      description             = null
      custom_request_headers  = null
      custom_response_headers  = null
      security_policy         = null
    }
  }
}
#END OPTIONAL LB
*/
