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

module "ilb-l7" {
  source     = "../../../../modules/net-lb-app-int"
  project_id = var.project_id
  name       = "ilb-l7-cr"
  region     = var.region
  backend_service_configs = {
    default = {
      project_id = module.service-project.project_id
      backends = [{
        group = "cr"
      }]
      health_checks = []
    }
  }
  health_check_configs = {}
  neg_configs = {
    cr = {
      project_id = module.service-project.project_id
      cloudrun = {
        region = var.region
        target_service = {
          name = var.cloudrun_svcname
        }
      }
    }
  }
  protocol = "HTTPS"
  ssl_certificates = {
    create_configs = {
      default = {
        certificate = google_privateca_certificate.ilb_cert.pem_certificate
        private_key = tls_private_key.ilb_cert_key.private_key_pem
      }
    }
  }
  vpc_config = {
    network    = var.created_resources.vpc_id
    subnetwork = var.created_resources.subnet_id
  }
}
