/**
 * Copyright 2024 Google LLC
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

module "producer-project" {
  source        = "../../../../../modules/project"
  name          = var.producer_project_id
  project_reuse = var.project_create_config != null ? null : {}

  billing_account = try(var.project_create_config.billing_account, null)
  parent          = try(var.project_create_config.parent, null)
  prefix          = var.prefix
  services = [
    "iam.googleapis.com",
    "run.googleapis.com",
    "compute.googleapis.com",
  ]
}

module "app" {
  source = "../../../../../modules/cloud-run-v2"

  name       = "example-app"
  project_id = module.producer-project.project_id
  region     = var.region
  containers = {
    hello = {
      image = "kennethreitz/httpbin:latest"
      ports = {
        http = { container_port = 80 }
      }
    }
  }
  ingress                = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  service_account_create = true
}

module "producer-ilb" {
  source     = "../../../../../modules/net-lb-app-int"
  name       = "example-app"
  project_id = module.producer-project.project_id
  region     = var.region

  backend_service_configs = {
    default = {
      backends = [{
        group = "my-neg"
      }]
      health_checks = []
    }
  }
  global_access        = true
  health_check_configs = {}
  neg_configs = {
    my-neg = {
      cloudrun = {
        region = var.region
        target_service = {
          name = module.app.service_name
        }
      }
    }
  }
  protocol = "HTTPS"
  ssl_certificates = {
    create_configs = {
      default = {
        # certificate and key could also be read via file() from external files
        certificate = tls_self_signed_cert.example.cert_pem
        private_key = tls_private_key.example.private_key_pem
      }
    }
  }
  vpc_config = {
    network    = module.producer-vpc.self_link
    subnetwork = module.producer-vpc.subnets["${var.region}/ilb-subnetwork"].self_link
  }
}

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "example" {
  private_key_pem = tls_private_key.example.private_key_pem

  subject {
    common_name  = "app.example.com"
    organization = "Org"
  }

  validity_period_hours = 12

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

module "producer-vpc" {
  source = "../../../../../modules/net-vpc"

  project_id = module.producer-project.project_id
  name       = "psc-ilb-network"
  subnets = [
    {
      ip_cidr_range = "10.0.0.0/24"
      name          = "ilb-subnetwork"
      region        = var.region
    },
  ]
  subnets_proxy_only = [
    {
      ip_cidr_range = "10.0.1.0/24"
      name          = "l7-ilb-proxy-subnet"
      region        = var.region
      active        = true
    },
  ]
  subnets_psc = [
    {
      ip_cidr_range = "10.3.0.0/16"
      name          = "psc-private-subnetwork"
      region        = var.region
    }
  ]
}

resource "google_compute_service_attachment" "exposed-psc-service" {
  name        = "producer-app"
  region      = var.region
  project     = module.producer-project.project_id
  description = "A service attachment configured with Terraform"

  enable_proxy_protocol = false
  connection_preference = "ACCEPT_MANUAL"
  nat_subnets           = [module.producer-vpc.subnets_psc["${var.region}/psc-private-subnetwork"].id]
  target_service        = module.producer-ilb.id
  consumer_accept_lists {
    connection_limit  = 10
    project_id_or_num = var.consumer_project_id
  }
}
