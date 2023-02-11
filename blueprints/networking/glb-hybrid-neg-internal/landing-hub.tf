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

################################################################################
#                                Base Hierarchy                                #
################################################################################

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

################################################################################
#                                  Networking                                  #
################################################################################

module "vpc_landing_untrusted" {
  source     = "../../../modules/net-vpc"
  project_id = module.project_landing.project_id
  name       = "landing-untrusted"

  routes = {
    spoke1-r1 = {
      dest_range    = var.vpc_spoke_config.r1_cidr
      next_hop_type = "ilb"
      next_hop      = module.nva_untrusted_ilbs["r1"].forwarding_rule_self_link
    }
    spoke1-r2 = {
      dest_range    = var.vpc_spoke_config.r2_cidr
      next_hop_type = "ilb"
      next_hop      = module.nva_untrusted_ilbs["r2"].forwarding_rule_self_link
    }
  }

  subnets = [
    {
      ip_cidr_range = var.vpc_landing_untrusted_config.r1_cidr
      name          = "untrusted-${var.region_configs.r1.region_name}"
      region        = var.region_configs.r1.region_name
    },
    {
      ip_cidr_range = var.vpc_landing_untrusted_config.r2_cidr
      name          = "untrusted-${var.region_configs.r2.region_name}"
      region        = var.region_configs.r2.region_name
    }
  ]
}

module "vpc_landing_trusted" {
  source     = "../../../modules/net-vpc"
  project_id = module.project_landing.project_id
  name       = "landing-trusted"
  subnets = [
    {
      ip_cidr_range = var.vpc_landing_trusted_config.r1_cidr
      name          = "trusted-${var.region_configs.r1.region_name}"
      region        = var.region_configs.r1.region_name
    },
    {
      ip_cidr_range = var.vpc_landing_trusted_config.r2_cidr
      name          = "trusted-${var.region_configs.r2.region_name}"
      region        = var.region_configs.r2.region_name
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
  for_each       = var.region_configs
  source         = "../../../modules/net-cloudnat"
  project_id     = module.project_landing.project_id
  region         = each.value.region_name
  name           = "nat-${each.value.region_name}"
  router_network = module.vpc_landing_untrusted.self_link
}

module "nva_instance_templates" {
  for_each               = var.region_configs
  source                 = "../../../modules/compute-vm"
  project_id             = module.project_landing.project_id
  can_ip_forward         = true
  create_template        = true
  name                   = "nva-${each.value.region_name}"
  service_account_create = true
  zone                   = each.value.zone

  metadata = {
    startup-script = templatefile(
      "${path.module}/data/nva-startup-script.tftpl",
      {
        gateway-trusted = cidrhost(module.vpc_landing_trusted.subnet_ips["${each.value.region_name}/trusted-${each.value.region_name}"], 1)
        spoke-r1-subnet = module.vpc_spoke_01.subnet_ips["${var.region_configs.r1.region_name}/spoke-01-${var.region_configs.r1.region_name}"]
        spoke-r2-subnet = module.vpc_spoke_01.subnet_ips["${var.region_configs.r2.region_name}/spoke-01-${var.region_configs.r2.region_name}"]
      }
    )
  }

  network_interfaces = [
    {
      network    = module.vpc_landing_untrusted.self_link
      subnetwork = module.vpc_landing_untrusted.subnet_self_links["${each.value.region_name}/untrusted-${each.value.region_name}"]
    },
    {
      network    = module.vpc_landing_trusted.self_link
      subnetwork = module.vpc_landing_trusted.subnet_self_links["${each.value.region_name}/trusted-${each.value.region_name}"]
    }
  ]

  tags = [
    "http-server",
    "https-server",
    "ssh"
  ]
}

module "nva_migs" {
  for_each          = var.region_configs
  source            = "../../../modules/compute-mig"
  project_id        = module.project_landing.project_id
  location          = each.value.zone
  name              = "nva-${each.value.region_name}"
  target_size       = 1
  instance_template = module.nva_instance_templates[each.key].template.self_link
}

module "nva_untrusted_ilbs" {
  for_each      = var.region_configs
  source        = "../../../modules/net-ilb"
  project_id    = module.project_landing.project_id
  region        = each.value.region_name
  name          = "nva-ilb-${each.value.region_name}"
  service_label = "nva-ilb-${each.value.region_name}"
  vpc_config = {
    network    = module.vpc_landing_untrusted.self_link
    subnetwork = module.vpc_landing_untrusted.subnet_self_links["${each.value.region_name}/untrusted-${each.value.region_name}"]
  }
  backends = [{
    group = module.nva_migs[each.key].group_manager.instance_group
  }]
  health_check_config = {
    tcp = {
      port = 22
    }
  }
}

module "hybrid-glb" {
  source     = "../../../modules/net-glb"
  project_id = module.project_landing.project_id
  name       = "hybrid-glb"
  backend_service_configs = {
    default = {
      backends = [
        {
          backend        = "neg-r1"
          balancing_mode = "RATE"
          max_rate       = { per_endpoint = 100 }
        },
        {
          backend        = "neg-r2"
          balancing_mode = "RATE"
          max_rate       = { per_endpoint = 100 }
        }
      ]
    }
  }
  neg_configs = {
    neg-r1 = {
      hybrid = {
        network = module.vpc_landing_untrusted.name
        zone    = var.region_configs.r1.zone
        endpoints = {
          r1 = {
            ip_address = (var.test_vms_behind_ilb
              ? module.test_vm_ilbs["r1"].forwarding_rule_address
              : module.test_vms["r1"].internal_ip
            )
            port = 80
          }
        }
      }
    }
    neg-r2 = {
      hybrid = {
        network = module.vpc_landing_untrusted.name
        zone    = var.region_configs.r2.zone
        endpoints = {
          r2 = {
            ip_address = (var.test_vms_behind_ilb
              ? module.test_vm_ilbs["r2"].forwarding_rule_address
              : module.test_vms["r2"].internal_ip
            )
            port = 80
          }
        }
      }
    }
  }
}
