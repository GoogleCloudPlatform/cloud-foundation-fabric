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
  api_id_prefix        = "api"
  function_name_prefix = "cf-hello"
  specs = { for region in var.regions : region =>
    templatefile("${path.module}/spec.yaml", {
      api_id        = "${local.api_id_prefix}-${region}"
      function_name = "${local.function_name_prefix}-${region}"
      region        = region
      project_id    = var.project_id
    })
  }
  backends = [
    for region in var.regions : {
      backend = google_compute_region_network_endpoint_group.serverless-negs[region].id
    }
  ]
}

resource "tls_private_key" "default" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "default" {
  private_key_pem = tls_private_key.default.private_key_pem
  subject {
    common_name  = "example.com"
    organization = "ACME Examples, Inc"
  }
  validity_period_hours = 720
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

module "project" {
  source = "../../../modules/project"
  name   = var.project_id
  project_reuse = {
    use_data_source = var._testing == null
    attributes      = var._testing
  }
  services = [
    "apigateway.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudfunctions.googleapis.com",
    "compute.googleapis.com",
    "run.googleapis.com",
    "servicemanagement.googleapis.com",
    "servicecontrol.googleapis.com"
  ]
}

module "sa" {
  source     = "../../../modules/iam-service-account"
  project_id = module.project.project_id
  name       = "sa-api"
}


module "functions" {
  for_each         = toset(var.regions)
  source           = "../../../modules/cloud-function-v2"
  project_id       = module.project.project_id
  name             = "${local.function_name_prefix}-${each.value}"
  bucket_name      = "bkt-${module.project.project_id}-${each.value}"
  region           = each.value
  ingress_settings = "ALLOW_ALL"
  bucket_config = {
    location                  = null
    lifecycle_delete_age_days = 1
  }
  bundle_config = {
    path = "${path.module}/function"
  }
  function_config = {
    entry_point = "helloGET"
    runtime     = "nodejs22"
  }
  service_account_create = true
  iam = {
    "roles/run.invoker" = [module.sa.iam_email]
  }
}

module "gateways" {
  for_each              = toset(var.regions)
  source                = "../../../modules/api-gateway"
  project_id            = module.project.project_id
  api_id                = "${local.api_id_prefix}-${each.value}"
  region                = each.value
  spec                  = local.specs[each.value]
  service_account_email = module.sa.email
}

module "glb" {
  source              = "../../../modules/net-lb-app-ext"
  project_id          = module.project.project_id
  name                = "glb"
  use_classic_version = false
  protocol            = "HTTPS"
  backend_service_configs = {
    default = {
      backends      = local.backends
      health_checks = []
      port_name     = ""
    }
  }
  ssl_certificates = {
    create_configs = {
      default = {
        certificate = tls_self_signed_cert.default.cert_pem
        private_key = tls_private_key.default.private_key_pem
      }
    }
  }
}

resource "google_compute_region_network_endpoint_group" "serverless-negs" {
  for_each              = toset(var.regions)
  provider              = google-beta
  name                  = "serverless-neg-${module.gateways[each.value].gateway_id}"
  project               = module.project.project_id
  network_endpoint_type = "SERVERLESS"
  region                = each.value
  serverless_deployment {
    platform = "apigateway.googleapis.com"
    resource = module.gateways[each.value].gateway_id
    url_mask = ""
  }
  lifecycle {
    create_before_destroy = true
  }
}
