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
  zones = {
    primary   = "${var.regions.primary}-b"
    secondary = "${var.regions.secondary}-b"
  }
}

module "project_landing" {
  source = "../../../modules/project"
  billing_account = (var.projects_create != null
    ? var.projects_create.billing_account_id
    : null
  )
  name = var.project_names.landing
  parent = (var.projects_create != null
    ? var.projects_create.parent
    : null
  )
  prefix         = var.prefix
  project_create = var.projects_create != null

  services = [
    "compute.googleapis.com",
    "networkmanagement.googleapis.com",
    # Logging and Monitoring
    "logging.googleapis.com",
    "monitoring.googleapis.com"
  ]
}

module "vpc_landing_untrusted" {
  source     = "../../../modules/net-vpc"
  project_id = module.project_landing.project_id
  name       = "landing-untrusted"

  routes = {
    spoke1-primary = {
      dest_range    = var.ip_config.spoke_primary
      next_hop_type = "ilb"
      next_hop      = module.nva_untrusted_ilbs["primary"].forwarding_rule_self_links[""]
    }
    spoke1-secondary = {
      dest_range    = var.ip_config.spoke_secondary
      next_hop_type = "ilb"
      next_hop      = module.nva_untrusted_ilbs["secondary"].forwarding_rule_self_links[""]
    }
  }

  subnets = [
    {
      ip_cidr_range = var.ip_config.untrusted_primary
      name          = "untrusted-${var.regions.primary}"
      region        = var.regions.primary
    },
    {
      ip_cidr_range = var.ip_config.untrusted_secondary
      name          = "untrusted-${var.regions.secondary}"
      region        = var.regions.secondary
    }
  ]
}

module "vpc_landing_trusted" {
  source     = "../../../modules/net-vpc"
  project_id = module.project_landing.project_id
  name       = "landing-trusted"
  subnets = [
    {
      ip_cidr_range = var.ip_config.trusted_primary
      name          = "trusted-${var.regions.primary}"
      region        = var.regions.primary
    },
    {
      ip_cidr_range = var.ip_config.trusted_secondary
      name          = "trusted-${var.regions.secondary}"
      region        = var.regions.secondary
    }
  ]
}

module "firewall_landing_untrusted" {
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.project_landing.project_id
  network    = module.vpc_landing_untrusted.name

  ingress_rules = {
    allow-ssh-from-hcs = {
      description = "Allow health checks to NVAs coming on port 22."
      targets     = ["ssh"]
      source_ranges = [
        "130.211.0.0/22",
        "35.191.0.0/16"
      ]
      rules = [{ protocol = "tcp", ports = [22] }]
    }
  }
}

module "nats_landing" {
  for_each       = var.regions
  source         = "../../../modules/net-cloudnat"
  project_id     = module.project_landing.project_id
  region         = each.value
  name           = "nat-${each.value}"
  router_network = module.vpc_landing_untrusted.self_link
}
