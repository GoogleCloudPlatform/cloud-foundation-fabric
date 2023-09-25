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
  ilb_create = var.phpipam_exposure == "INTERNAL"
}

# default ssl certificate
resource "tls_private_key" "default" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "default" {
  private_key_pem       = tls_private_key.default.private_key_pem
  validity_period_hours = 720
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
  subject {
    common_name  = local.domain
    organization = "ACME Examples, Inc"
  }
}

module "ilb-l7" {
  source     = "../../../modules/net-lb-app-int"
  count      = local.ilb_create ? 1 : 0
  project_id = var.project_id
  name       = "ilb-l7-cr"
  protocol   = "HTTPS"
  region     = var.region

  backend_service_configs = {
    default = {
      project_id = var.project_id
      backends = [
        {
          group = "phpipam"
        }
      ]
      health_checks = []
    }
  }
  health_check_configs = {
    default = {
      https = { port = 443 }
    }
  }
  neg_configs = {
    phpipam = {
      project_id = var.project_id
      cloudrun = {
        region = var.region
        target_service = {
          name = module.cloud_run.service_name
        }
      }
    }
  }
  ssl_certificates = {
    create_configs = {
      default = {
        # certificate and key could also be read via file() from external files
        certificate = tls_self_signed_cert.default.cert_pem
        private_key = tls_private_key.default.private_key_pem
      }
    }
  }
  vpc_config = {
    network    = local.network
    subnetwork = local.subnetwork
  }
}
