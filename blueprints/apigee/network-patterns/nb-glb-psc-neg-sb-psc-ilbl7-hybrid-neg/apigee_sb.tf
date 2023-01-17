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

module "apigee_ilb_l7" {
  source     = "../../../../modules/net-ilb-l7"
  name       = "apigee-ilb"
  project_id = module.apigee_project.project_id
  region     = var.region
  backend_service_configs = {
    default = {
      backends = [{
        balancing_mode = "RATE"
        group          = "my-neg"
        max_rate       = { per_endpoint = 1 }
      }]
    }
  }
  neg_configs = {
    my-neg = {
      hybrid = {
        zone = var.zone
        endpoints = {
          e-0 = {
            ip_address = module.onprem_ilb_l7.address
            port       = 80
          }
        }
      }
    }
  }
  health_check_configs = {
    default = {
      http = {
        port = 80
      }
    }
  }
  vpc_config = {
    network    = module.apigee_vpc.self_link
    subnetwork = module.apigee_vpc.subnet_self_links["${var.region}/subnet"]
  }
  depends_on = [
    module.apigee_vpc.subnets_proxy_only
  ]
}

resource "google_compute_service_attachment" "service_attachment" {
  name                  = "service-attachment"
  project               = module.apigee_project.project_id
  region                = var.region
  enable_proxy_protocol = false
  connection_preference = "ACCEPT_AUTOMATIC"
  nat_subnets           = [module.apigee_vpc.subnets_psc["${var.region}/subnet-psc"].self_link]
  target_service        = module.apigee_ilb_l7.forwarding_rule.id
}
