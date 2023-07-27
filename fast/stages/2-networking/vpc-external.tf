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

# tfdoc:file:description Landing VPC and related resources.



# external VPC

module "external-vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.net-project.project_id
  name       = "prod-core-external-0"
  mtu        = 1500
  dns_policy = {
    inbound = false
    logging = false
  }
  subnets = [
    {
      ip_cidr_range = "100.100.1.0/28"
      name          = "prod-core-external-0-nva-primary"
      region        = "europe-west8"
    },
    {
      ip_cidr_range = "100.100.1.128/28"
      name          = "prod-core-external-0-nva-secondary"
      region        = "europe-west12"
    }
  ]
}

module "external-firewall" {
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.net-project.project_id
  network    = module.external-vpc.name
  default_rules_config = {
    disabled = true
  }
  factories_config = {
    cidr_tpl_file = "${var.factories_config.data_dir}/cidrs.yaml"
    rules_folder  = "${var.factories_config.data_dir}/firewall-rules/external"
  }
}

module "external-addresses" {
  source     = "../../../modules/net-address"
  project_id = module.net-project.project_id
  internal_addresses = {
    external-lb-primary = {
      region     = var.regions.primary
      subnetwork = module.external-vpc.subnet_self_links["${var.regions.primary}/prod-core-external-0-nva-primary"]
      address    = cidrhost(module.external-vpc.subnet_ips["${var.regions.primary}/prod-core-external-0-nva-primary"], -3)
    }
    external-lb-secondary = {
      region     = var.regions.secondary
      subnetwork = module.external-vpc.subnet_self_links["${var.regions.secondary}/prod-core-external-0-nva-secondary"]
      address    = cidrhost(module.external-vpc.subnet_ips["${var.regions.secondary}/prod-core-external-0-nva-secondary"], -3)
    }
  }
}

module "external-ilb-primary" {
  source     = "../../../modules/net-lb-int"
  project_id = module.net-project.project_id
  region     = var.regions.primary
  name       = "external-lb-primary"
  vpc_config = {
    network    = module.external-vpc.name
    subnetwork = module.external-vpc.subnet_self_links["${var.regions.primary}/prod-core-external-0-nva-primary"]
  }
  address       = module.external-addresses.internal_addresses["external-lb-primary"].address
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


module "external-ilb-secondary" {
  source     = "../../../modules/net-lb-int"
  project_id = module.net-project.project_id
  region     = var.regions.secondary
  name       = "external-lb-secondary"
  vpc_config = {
    network    = module.external-vpc.name
    subnetwork = module.external-vpc.subnet_self_links["${var.regions.secondary}/prod-core-external-0-nva-secondary"]
  }
  address       = module.external-addresses.internal_addresses["external-lb-secondary"].address
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
