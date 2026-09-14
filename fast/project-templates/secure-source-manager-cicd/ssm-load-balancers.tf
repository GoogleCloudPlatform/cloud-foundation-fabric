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
  project_id = var.project_ids.ssm
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
  project_id = var.project_ids.ssm
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

# Test chain: a second consumer of the same service attachment, in a second VPC
# and its own project, which is where these load balancers belong in a design
# with segregated environments. Static values on purpose — this is throwaway,
# and parameterising it would imply it is part of the template. Needs the
# proxy-only subnet ilb-l7 in europe-west4 on the prod spoke, and credentials
# with rights in ldj-prod-net-spoke-0, which the automation account lacks.
module "ssm-lb-prod-test" {
  source     = "../../../modules/net-lb-proxy-int"
  project_id = "ldj-prod-net-spoke-0"
  region     = "europe-west4"
  name       = "test-0-ssm-prod-0"
  forwarding_rules_config = {
    "" = {
      port = 443
    }
  }
  backend_service_config = {
    backends = [{
      group = "psc"
    }]
  }
  neg_configs = {
    psc = {
      psc = {
        network        = "projects/ldj-prod-net-spoke-0/global/networks/prod-spoke-0"
        region         = "europe-west4"
        subnetwork     = "projects/ldj-prod-net-spoke-0/regions/europe-west4/subnetworks/gce"
        target_service = module.ssm-instance.http_service_attachment
      }
    }
  }
  vpc_config = {
    network    = "projects/ldj-prod-net-spoke-0/global/networks/prod-spoke-0"
    subnetwork = "projects/ldj-prod-net-spoke-0/regions/europe-west4/subnetworks/gce"
  }
}
