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

# tfdoc:file:description External VPC.

module "ext-vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.project.project_id
  name       = "ext"
  mtu        = 1500
  subnets = [
    {
      name          = "ext"
      region        = var.region
      ip_cidr_range = var.ip_ranges.ext
    }
  ]
}

module "nat" {
  source         = "../../../modules/net-cloudnat"
  project_id     = module.project.project_id
  router_network = module.ext-vpc.name
  region         = var.region
  name           = "default"
}

module "ext-firewall" {
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.project.project_id
  network    = module.ext-vpc.name
  default_rules_config = {
    admin_ranges = [var.ip_ranges.rfc1918_10]
    ssh_ranges   = ["35.235.240.0/20", "35.191.0.0/16", "130.211.0.0/22", "209.85.152.0/22", "209.85.204.0/22"]
  }
}

resource "google_compute_route" "ext-rfc1918-10" {
  project      = module.project.project_id
  network      = module.ext-vpc.name
  name         = "ext-rfc1918-10"
  description  = "Terraform-managed."
  dest_range   = var.ip_ranges.rfc1918_10
  priority     = 1000
  next_hop_ilb = module.ext-lb.forwarding_rule_self_links[""]
}

module "ext-addresses" {
  source     = "../../../modules/net-address"
  project_id = module.project.project_id
  internal_addresses = {
    ext = {
      region     = var.region
      subnetwork = module.ext-vpc.subnet_self_links["${var.region}/ext"]
      address    = cidrhost(module.ext-vpc.subnet_ips["${var.region}/ext"], -3)
    }
  }
}

module "ext-lb" {
  source     = "../../../modules/net-lb-int"
  project_id = module.project.project_id
  region     = var.region
  name       = "ext-lb"
  vpc_config = {
    network    = module.ext-vpc.name
    subnetwork = module.ext-vpc.subnet_self_links["${var.region}/ext"]
  }
  forwarding_rules_config = {
    "" = {
      global_access = false
      address       = module.ext-addresses.internal_addresses["ext"].address
    }
  }
  backends = [
    {
      failover       = false
      group          = google_compute_instance_group.nva-a.id
      balancing_mode = "CONNECTION"
    },
    {
      failover       = false
      group          = google_compute_instance_group.nva-b.id
      balancing_mode = "CONNECTION"
    },
  ]
  health_check_config = {
    tcp = {
      port = 22
    }
  }
}
