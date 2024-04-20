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

# tfdoc:file:description Load balancer and VPC resources.

locals {
  # define regions for both instances and lb for easy access
  regions = keys(var.vpc_config.subnets)
}

module "vpc" {
  source     = "../../net-vpc"
  count      = var.vpc_config.proxy_subnets_config == null ? 0 : 1
  project_id = regex("projects/([^/]+)/", var.vpc_config.network)[0]
  name       = regex("global/networks/([^/]+)$", var.vpc_config.network)[0]
  vpc_create = false
  subnets_proxy_only = [
    for k, v in var.vpc_config.proxy_subnets_config : {
      ip_cidr_range = v
      name          = "${var.prefix}-proxy-${local.region_shortnames[k]}"
      region        = k
      active        = true
      global        = true
    }
  ]
}

module "load-balancer" {
  source     = "../../net-lb-app-int-cross-region"
  name       = var.prefix
  project_id = var.project_id
  backend_service_configs = {
    default = {
      port_name = "http"
      backends = [
        for k, v in module.instances : { group = v.group.id }
      ]
    }
  }
  vpc_config = {
    network     = var.vpc_config.network
    subnetworks = var.vpc_config.subnets
  }
  depends_on = [module.vpc]
}

module "dns" {
  source     = "../../dns"
  project_id = var.project_id
  name       = var.prefix
  zone_config = {
    domain = var.dns_config.domain
    private = {
      client_networks = (
        var.dns_config.client_networks != null
        ? var.dns_config.client_networks
        : [var.vpc_config.network]
      )
    }
  }
  recordsets = {
    "A ${coalesce(var.dns_config.hostname, var.prefix)}" = {
      geo_routing = [
        for k in local.regions : {
          location = k
          health_checked_targets = [
            {
              load_balancer_type = "globalL7ilb"
              ip_address         = module.load-balancer.addresses[k]
              port               = "80"
              ip_protocol        = "tcp"
              network_url        = var.vpc_config.network
              project            = var.project_id
            }
        ] }
      ]
    }
  }
}

module "firewall" {
  source               = "../../net-vpc-firewall"
  count                = var.vpc_config.firewall_config == null ? 0 : 1
  project_id           = var.project_id
  network              = var.vpc_config.network
  default_rules_config = { disabled = true }
  ingress_rules = merge(
    {
      "ingress-${var.prefix}-proxies" = {
        description   = "Allow load balancer proxy traffic to instances."
        source_ranges = var.vpc_config.firewall_config.proxy_subnet_ranges
        targets       = [var.prefix]
        rules         = [{ protocol = "tcp", ports = [80, 443] }]
      }
    },
    var.vpc_config.firewall_config.client_allowed_ranges == null ? {} : {
      "ingress-${var.prefix}-http-clients" = {
        description   = "Allow client HTTP traffic to instances."
        source_ranges = var.vpc_config.firewall_config.client_allowed_ranges
        targets       = [var.prefix]
        rules         = [{ protocol = "tcp", ports = [80, 443] }]
      }
    },
    var.vpc_config.firewall_config.enable_health_check != true ? {} : {
      "ingress-${var.prefix}-health-checks" = {
        description   = "Allow health check traffic to instances."
        source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
        targets       = [var.prefix]
        rules         = [{ protocol = "tcp", ports = [80, 443] }]
      }
    },
    var.vpc_config.firewall_config.enable_iap_ssh != true ? {} : {
      "ingress-${var.prefix}-iap-ssh" = {
        description   = "Allow SSH traffic to instances via IAP."
        source_ranges = ["35.235.240.0/20"]
        targets       = [var.prefix]
        rules         = [{ protocol = "tcp", ports = [22] }]
      }
    }
  )
}
