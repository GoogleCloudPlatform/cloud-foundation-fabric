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

module "dmz-vpc" {
  source                          = "../../../modules/net-vpc"
  project_id                      = module.net-project.project_id
  name                            = "prod-core-dmz-0"
  mtu                             = 1500
  delete_default_routes_on_create = true
  create_googleapis_routes = {
    restricted   = false
    restricted-6 = false
    private      = false
    private-6    = false
  }
  subnets = [
    {
      ip_cidr_range = "100.101.2.0/28"
      name          = "prod-core-dmz-0-nva-primary"
      region        = "europe-west8"
    },
    {
      ip_cidr_range = "100.102.2.128/28"
      name          = "prod-core-dmz-0-nva-secondary"
      region        = "europe-west12"
    }
  ]
}

resource "google_compute_route" "dmz-primary" {
  project      = module.net-project.project_id
  network      = module.dmz-vpc.name
  name         = "dmz-primary"
  description  = "Terraform-managed."
  dest_range   = "100.101.0.0/16"
  priority     = 1000
  next_hop_ilb = module.dmz-ilb-primary.forwarding_rule_self_link
}

resource "google_compute_route" "dmz-secondary" {
  project      = module.net-project.project_id
  network      = module.dmz-vpc.name
  name         = "dmz-secondary"
  description  = "Terraform-managed."
  dest_range   = "100.102.0.0/16"
  priority     = 1000
  next_hop_ilb = module.dmz-ilb-secondary.forwarding_rule_self_link
}

module "dmz-firewall" {
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.net-project.project_id
  network    = module.dmz-vpc.name
  default_rules_config = {
    disabled = true
  }
  factories_config = {
    cidr_tpl_file = "${var.factories_config.data_dir}/cidrs.yaml"
    rules_folder  = "${var.factories_config.data_dir}/firewall-rules/dmz"
  }
}

module "dmz-nat-primary" {
  source         = "../../../modules/net-cloudnat"
  project_id     = module.net-project.project_id
  region         = var.regions.primary
  name           = local.region_shortnames[var.regions.primary]
  router_create  = true
  router_name    = "prod-nat-${local.region_shortnames[var.regions.primary]}"
  router_network = module.dmz-vpc.name
  router_asn     = 4200001024
}

module "dmz-nat-secondary" {
  source         = "../../../modules/net-cloudnat"
  project_id     = module.net-project.project_id
  region         = var.regions.secondary
  name           = local.region_shortnames[var.regions.secondary]
  router_create  = true
  router_name    = "prod-nat-${local.region_shortnames[var.regions.secondary]}"
  router_network = module.dmz-vpc.name
  router_asn     = 4200001024
}

module "dmz-addresses" {
  source     = "../../../modules/net-address"
  project_id = module.net-project.project_id
  internal_addresses = {
    dmz-lb-primary = {
      region     = var.regions.primary
      subnetwork = module.dmz-vpc.subnet_self_links["${var.regions.primary}/prod-core-dmz-0-nva-primary"]
      address    = cidrhost(module.dmz-vpc.subnet_ips["${var.regions.primary}/prod-core-dmz-0-nva-primary"], -3)
    }
    dmz-lb-secondary = {
      region     = var.regions.secondary
      subnetwork = module.dmz-vpc.subnet_self_links["${var.regions.secondary}/prod-core-dmz-0-nva-secondary"]
      address    = cidrhost(module.dmz-vpc.subnet_ips["${var.regions.secondary}/prod-core-dmz-0-nva-secondary"], -3)
    }
  }
}

module "dmz-ilb-primary" {
  source     = "../../../modules/net-lb-int"
  project_id = module.net-project.project_id
  region     = var.regions.primary
  name       = "dmz-lb-primary"
  vpc_config = {
    network    = module.dmz-vpc.name
    subnetwork = module.dmz-vpc.subnet_self_links["${var.regions.primary}/prod-core-dmz-0-nva-primary"]
  }
  address       = module.dmz-addresses.internal_addresses["dmz-lb-primary"].address
  service_label = var.prefix
  global_access = true
  backends = [for z in local.zones :
    {
      failover       = false
      group          = google_compute_instance_group.nva-primary[z].id
      balancing_mode = "CONNECTION"
    }
  ]
  health_check_config = {
    tcp = {
      port = 22
    }
  }
}

module "dmz-ilb-secondary" {
  source     = "../../../modules/net-lb-int"
  project_id = module.net-project.project_id
  region     = var.regions.secondary
  name       = "dmz-lb-secondary"
  vpc_config = {
    network    = module.dmz-vpc.name
    subnetwork = module.dmz-vpc.subnet_self_links["${var.regions.secondary}/prod-core-dmz-0-nva-secondary"]
  }
  address       = module.dmz-addresses.internal_addresses["dmz-lb-secondary"].address
  service_label = var.prefix
  global_access = true
  backends = [for z in ["a"] :
    {
      failover       = false
      group          = google_compute_instance_group.nva-secondary[z].id
      balancing_mode = "CONNECTION"
    }
  ]
  health_check_config = {
    tcp = {
      port = 22
    }
  }
}

