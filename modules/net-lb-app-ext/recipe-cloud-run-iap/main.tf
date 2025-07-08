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
  hostname = "${module.addresses.global_addresses.glb.address}.nip.io"
  url      = "https://${local.hostname}"
}

module "project" {
  source = "../../../modules/project"
  name   = var.project_id
  project_reuse = {
    use_data_source = var._testing == null
    attributes      = var._testing
  }
  services = [
    "cloudbuild.googleapis.com",
    "iap.googleapis.com",
    "run.googleapis.com"
  ]
}

module "application_service_account" {
  source     = "../../../modules/iam-service-account"
  project_id = var.project_id
  name       = "application"
  iam = {
    "roles/iam.serviceAccountTokenCreator" = var.impersonators
  }
}

resource "google_iap_brand" "iap_brand" {
  support_email     = var.support_email
  application_title = "Test Application"
  project           = module.project.id
}

resource "google_iap_client" "iap_client" {
  display_name = "Test Client"
  brand        = google_iap_brand.iap_brand.name
}

module "backend_service" {
  source     = "../../../modules/cloud-run-v2"
  project_id = module.project.id
  name       = "backend"
  region     = var.region
  containers = {
    hello = {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
    }
  }
  iam = {
    "roles/run.invoker" = [
      module.project.service_agents.iap.iam_email
    ]
  }
  deletion_protection    = false
  service_account_create = true
}

module "addresses" {
  source     = "../../../modules/net-address"
  project_id = module.project.id
  global_addresses = {
    glb = {}
  }
}

module "glb" {
  source              = "../../../modules/net-lb-app-ext"
  project_id          = module.project.id
  name                = "glb"
  protocol            = "HTTPS"
  use_classic_version = false
  forwarding_rules_config = {
    "" = {
      address = (
        module.addresses.global_addresses.glb.address
      )
    }
  }
  backend_service_configs = {
    default = {
      backends = [
        { backend = "neg-backend" }
      ]
      health_checks = []
      iap_config = {
        oauth2_client_id     = google_iap_client.iap_client.client_id
        oauth2_client_secret = google_iap_client.iap_client.secret
      }
      port_name = ""
    }
  }
  health_check_configs = {}
  neg_configs = {
    neg-backend = {
      cloudrun = {
        region = var.region
        target_service = {
          name = "backend"
        }
      }
    }
  }
  ssl_certificates = {
    managed_configs = {
      default = {
        domains = [local.hostname]
      }
    }
  }
}

resource "google_iap_web_backend_service_iam_binding" "iam_bindings" {
  project             = module.project.id
  web_backend_service = module.glb.backend_service_names["default"]
  role                = "roles/iap.httpsResourceAccessor"
  members = concat(
    var.accesors,
    [
      module.application_service_account.iam_email
  ])
}

resource "google_iap_settings" "iap_settings" {
  name = "projects/${module.project.number}/iap_web/forwarding_rule/services/${module.glb.forwarding_rules[""].name}"
  access_settings {
    cors_settings {
      allow_http_options = true
    }
    oauth_settings {
      programmatic_clients = [
        google_iap_client.iap_client.client_id
      ]
    }
  }
}
