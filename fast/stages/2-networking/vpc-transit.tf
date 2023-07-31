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
#                               Transit primary                                #
################################################################################

module "transit-primary-vpc" {
  source                          = "../../../modules/net-vpc"
  project_id                      = module.net-project.project_id
  name                            = "prod-core-transit-primary-0"
  mtu                             = 1500
  delete_default_routes_on_create = true
  create_googleapis_routes = {
    restricted   = true
    restricted-6 = false
    private      = true
    private-6    = false
  }
  psa_config = {
    ranges        = { gcve-transit-primary = "100.101.129.0/24" }
    export_routes = true
    import_routes = true
  }
  subnets = [
    {
      ip_cidr_range = "100.101.128.0/28"
      name          = "prod-core-transit-primary-0-nva"
      region        = "europe-west8"
    }
  ]
}

resource "google_compute_route" "transit-primary" {
  project      = module.net-project.project_id
  network      = module.transit-primary-vpc.name
  name         = "transit-primary"
  description  = "Terraform-managed."
  dest_range   = "0.0.0.0/0"
  priority     = 1000
  next_hop_ilb = module.transit-primary-ilb.forwarding_rule_self_link
}

module "transit-primary-firewall" {
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.net-project.project_id
  network    = module.transit-primary-vpc.name
  default_rules_config = {
    disabled = true
  }
  factories_config = {
    cidr_tpl_file = "${var.factories_config.data_dir}/cidrs.yaml"
    rules_folder  = "${var.factories_config.data_dir}/firewall-rules/transit-primary"
  }
}


module "transit-primary-addresses" {
  source     = "../../../modules/net-address"
  project_id = module.net-project.project_id
  internal_addresses = {
    transit-primary-lb = {
      region     = var.regions.primary
      subnetwork = module.transit-primary-vpc.subnet_self_links["${var.regions.primary}/prod-core-transit-primary-0-nva"]
      address    = cidrhost(module.transit-primary-vpc.subnet_ips["${var.regions.primary}/prod-core-transit-primary-0-nva"], -3)
    }
  }
}

module "transit-primary-ilb" {
  source     = "../../../modules/net-lb-int"
  project_id = module.net-project.project_id
  region     = var.regions.primary
  name       = "transit-primary-lb"
  vpc_config = {
    network    = module.transit-primary-vpc.name
    subnetwork = module.transit-primary-vpc.subnet_self_links["${var.regions.primary}/prod-core-transit-primary-0-nva"]
  }
  address       = module.transit-primary-addresses.internal_addresses["transit-primary-lb"].address
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

################################################################################
#                              Transit secondary                               #
################################################################################

module "transit-secondary-vpc" {
  source                          = "../../../modules/net-vpc"
  project_id                      = module.net-project.project_id
  name                            = "prod-core-transit-secondary-0"
  mtu                             = 1500
  delete_default_routes_on_create = true
  create_googleapis_routes = {
    restricted   = true
    restricted-6 = false
    private      = true
    private-6    = false
  }
  psa_config = {
    ranges        = { gcve-transit-secondary = "100.102.129.0/24" }
    export_routes = true
    import_routes = true
  }
  subnets = [
    {
      ip_cidr_range = "100.102.128.0/28"
      name          = "prod-core-transit-secondary-0-nva"
      region        = "europe-west12"
    }
  ]
}

resource "google_compute_route" "transit-secondary" {
  project      = module.net-project.project_id
  network      = module.transit-secondary-vpc.name
  name         = "transit-secondary"
  description  = "Terraform-managed."
  dest_range   = "0.0.0.0/0"
  priority     = 1000
  next_hop_ilb = module.transit-secondary-ilb.forwarding_rule_self_link
}

module "transit-secondary-firewall" {
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.net-project.project_id
  network    = module.transit-secondary-vpc.name
  default_rules_config = {
    disabled = true
  }
  factories_config = {
    cidr_tpl_file = "${var.factories_config.data_dir}/cidrs.yaml"
    rules_folder  = "${var.factories_config.data_dir}/firewall-rules/transit-secondary"
  }
}

module "transit-secondary-addresses" {
  source     = "../../../modules/net-address"
  project_id = module.net-project.project_id
  internal_addresses = {
    transit-secondary-lb = {
      region     = var.regions.secondary
      subnetwork = module.transit-secondary-vpc.subnet_self_links["${var.regions.secondary}/prod-core-transit-secondary-0-nva"]
      address    = cidrhost(module.transit-secondary-vpc.subnet_ips["${var.regions.secondary}/prod-core-transit-secondary-0-nva"], -3)
    }
  }
}

module "transit-secondary-ilb" {
  source     = "../../../modules/net-lb-int"
  project_id = module.net-project.project_id
  region     = var.regions.secondary
  name       = "transit-secondary-lb"
  vpc_config = {
    network    = module.transit-secondary-vpc.name
    subnetwork = module.transit-secondary-vpc.subnet_self_links["${var.regions.secondary}/prod-core-transit-secondary-0-nva"]
  }
  address       = module.transit-secondary-addresses.internal_addresses["transit-secondary-lb"].address
  service_label = var.prefix
  global_access = true
  #TOFIX: define a local for zone(s) to be used for NVAs in primary and secondary regions
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
