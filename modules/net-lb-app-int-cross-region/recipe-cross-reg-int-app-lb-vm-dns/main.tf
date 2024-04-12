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

locals {
  _instance_subnets = (
    var.vpc_config.instance_subnets == null
    ? var.vpc_config.load_balancer_subnets
    : var.vpc_config.instance_subnets
  )
  _instance_regions = {
    for v in var.vpc_config.instance_subnets :
    regex("/regions/([^/]+)/", v) => v
  }
  _lb_subnets = [
    for v in var.vpc_config.load_balancer_subnets : merge(
      regex("/regions/(?P<region>[^/]+)/subnetworks/(?P<name>[^/]+)$"),
      { subnet = v }
    )
  ]
  instances = flatten([
    for region, subnet in local._instance_regions : [
      for zone in var.instances_config.zones : [
        for num in range(var.instances_config.count) : {
          key    = join("-", [var.prefix, region, zone, num])
          subnet = subnet
          zone   = "${region}-${zone}"
        }
      ]
    ]
  ])
  lb_regions = {
    for v in var.vpc_config.load_balancer_subnets :
    regex("/regions/([^/]+)/", v) => v
  }
  lb_subnets = {
    for v in local._lb_subnets :
    "${local.region_shortnames[v.region]}-${v.name}" => v.subnet
  }
}

module "instance-sa" {
  source       = "../../iam-service-account"
  project_id   = var.project_id
  name         = "vm-default"
  prefix       = var.prefix
  display_name = "Cross-region LB instances service account"
  iam_project_roles = {
    (var.project_id) = [
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter"
    ]
  }
}

module "instances" {
  source        = "../../compute-vm"
  for_each      = { for v in local.instances : v.key => v }
  project_id    = var.project_id
  zone          = each.value.zone
  name          = each.key
  instance_type = var.instances_config.machine_type
  boot_disk = {
    initialize_params = {
      image = "projects/cos-cloud/global/images/family/cos-stable"
    }
  }
  network_interfaces = [{
    network    = var.vpc_config.network
    subnetwork = each.value.subnet
  }]
  tags = [
    "${var.prefix}-ssh", "${var.prefix}-http-server", "${var.prefix}-proxy"
  ]
  metadata = {
    user-data = file("nginx-cloud-config.yaml")
  }
  service_account = {
    email = module.instance-sa.email
  }
  group = {
    named_ports = {
      http  = 80
      https = 443
    }
  }
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
    subnetworks = local.lb_subnets
  }
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
        for k, v in local.lb_regions : {
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
