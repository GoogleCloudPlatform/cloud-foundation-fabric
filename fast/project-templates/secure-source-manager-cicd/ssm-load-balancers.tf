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

locals {
  ssm_lb_ip = "${local.prefix}${var.name}-lb"
}

module "ssm-lb-ip" {
  source     = "../../../modules/net-address"
  project_id = module.ssm-project.project_id
  internal_addresses = {
    # key is the address name, which is also the key of the module output
    (local.ssm_lb_ip) = {
      address    = var.load_balancer_config.address
      purpose    = "SHARED_LOADBALANCER_VIP"
      region     = local.location
      subnetwork = local.lb_subnetwork
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
  region     = local.location
  name       = "${local.prefix}${var.name}-${each.key}"
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
        network        = local.lb_network
        region         = local.location
        subnetwork     = local.lb_subnetwork
        target_service = module.ssm-instance["${each.key}_service_attachment"]
      }
    }
  }
  vpc_config = {
    network    = local.lb_network
    subnetwork = local.lb_subnetwork
  }
}
