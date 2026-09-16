/**
 * Copyright 2026 Google LLC
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

module "ssm-lb-ip" {
  source     = "../../../modules/net-address"
  project_id = module.ssm-project.project_id
  internal_addresses = {
    # key is the address name, which is also the key of the module output
    (local.ssm_lb_ip) = {
      purpose    = "SHARED_LOADBALANCER_VIP"
      region     = var.locations.ssm
      subnetwork = var.network_config.subnetwork
    }
  }
}

module "ssm-lb" {
  for_each = {
    http = 443
    ssh  = 22
  }
  source     = "../../../modules/net-lb-proxy-int"
  project_id = module.ssm-project.project_id
  region     = var.locations.ssm
  name       = "${local.prefix}dev-0-${each.key}"
  forwarding_rules_config = {
    "" = {
      address = module.ssm-lb-ip.internal_addresses[local.ssm_lb_ip].address
      port    = each.value
    }
  }
  # a PSC NEG backend only accepts the UTILIZATION balancing mode, which is the
  # module default: CONNECTION and RATE are refused by the API
  backend_service_config = {
    backends = [{
      group = "psc"
    }]
  }
  neg_configs = {
    psc = {
      psc = {
        network        = var.network_config.vpc_self_link
        region         = var.locations.ssm
        subnetwork     = var.network_config.subnetwork
        target_service = module.ssm-instance["${each.key}_service_attachment"]
      }
    }
  }
  vpc_config = {
    network    = var.network_config.vpc_self_link
    subnetwork = var.network_config.subnetwork
  }
}

