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

module "project_spoke_01" {
  source = "../../../modules/project"
  billing_account = (var.projects_create != null
    ? var.projects_create.billing_account_id
    : null
  )
  name = var.project_names.spoke_01
  parent = (var.projects_create != null
    ? var.projects_create.parent
    : null
  )
  prefix = var.prefix

  services = [
    "compute.googleapis.com",
    "networkmanagement.googleapis.com",
    # Logging and Monitoring
    "logging.googleapis.com",
    "monitoring.googleapis.com"
  ]
}

module "vpc_spoke_01" {
  source     = "../../../modules/net-vpc"
  project_id = module.project_spoke_01.project_id
  name       = "spoke-01"
  subnets = [
    {
      ip_cidr_range = var.vpc_spoke_config.r1_cidr
      name          = "spoke-01-${var.region_configs.r1.region_name}"
      region        = var.region_configs.r1.region_name
    },
    {
      ip_cidr_range = var.vpc_spoke_config.r2_cidr
      name          = "spoke-01-${var.region_configs.r2.region_name}"
      region        = var.region_configs.r2.region_name
    }
  ]
  peering_config = {
    peer_vpc_self_link = module.vpc_landing_trusted.self_link
    import_routes      = true
  }
}

module "firewall_spoke_01" {
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.project_spoke_01.project_id
  network    = module.vpc_spoke_01.name

  ingress_rules = {
    allow-nva-hcs = {
      description = "Allow health checks coming on port 80 and 443 from NVAs."
      targets     = ["http-server", "https-server"]
      source_ranges = [
        module.vpc_landing_trusted.subnet_ips["${var.region_configs.r1.region_name}/trusted-${var.region_configs.r1.region_name}"],
        module.vpc_landing_trusted.subnet_ips["${var.region_configs.r2.region_name}/trusted-${var.region_configs.r2.region_name}"]
      ]
      rules = [{ protocol = "tcp", ports = [80, 443] }]
    }
  }
}

# NAT is used to install nginx for test purposed, even if NVAs are still not ready

module "nats_spoke_01" {
  for_each       = var.region_configs
  source         = "../../../modules/net-cloudnat"
  name           = "spoke-01-${each.value.region_name}"
  project_id     = module.project_spoke_01.project_id
  region         = each.value.region_name
  router_network = module.vpc_spoke_01.name
}

module "test_vms" {
  for_each               = var.region_configs
  source                 = "../../../modules/compute-vm"
  name                   = "spoke-01-${each.value.region_name}"
  project_id             = module.project_spoke_01.project_id
  create_template        = var.test_vms_behind_ilb
  service_account_create = true
  zone                   = each.value.zone

  metadata = {
    startup-script = "apt update && apt install -y nginx"
  }

  network_interfaces = [{
    network    = module.vpc_spoke_01.self_link
    subnetwork = module.vpc_spoke_01.subnet_self_links["${each.value.region_name}/spoke-01-${each.value.region_name}"]
  }]

  tags = [
    "http-server",
    "https-server",
    "ssh"
  ]
}

module "test_vm_migs" {
  for_each          = var.test_vms_behind_ilb ? var.region_configs : {}
  source            = "../../../modules/compute-mig"
  project_id        = module.project_spoke_01.project_id
  location          = each.value.zone
  name              = "test-vm-${each.value.region_name}"
  target_size       = 1
  instance_template = module.test_vms[each.key].template.self_link
}

module "test_vm_ilbs" {
  for_each      = var.test_vms_behind_ilb ? var.region_configs : {}
  source        = "../../../modules/net-ilb"
  project_id    = module.project_spoke_01.project_id
  region        = each.value.region_name
  name          = "test-vm-ilb-${each.value.region_name}"
  service_label = "test-vm-ilb-${each.value.region_name}"
  vpc_config = {
    network    = module.vpc_spoke_01.self_link
    subnetwork = module.vpc_spoke_01.subnet_self_links["${each.value.region_name}/spoke-01-${each.value.region_name}"]
  }
  backends = [{
    group = module.test_vm_migs[each.key].group_manager.instance_group
  }]
  health_check_config = {
    tcp = {
      port = 80
    }
  }
}
