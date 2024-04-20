/**
 * Copyright 2022 Google LLC
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
  # routing_config should be aligned to the NVA network interfaces - i.e.
  # local.routing_config[0] sets up the first interface, and so on.
  routing_config = [
    {
      name                = "dmz"
      enable_masquerading = true
      routes = [
        var.gcp_ranges.gcp_dmz_primary,
        var.gcp_ranges.gcp_dmz_secondary,
      ]
    },
    {
      name = "landing"
      routes = [
        var.gcp_ranges.gcp_dev_primary,
        var.gcp_ranges.gcp_dev_secondary,
        var.gcp_ranges.gcp_landing_landing_primary,
        var.gcp_ranges.gcp_landing_landing_secondary,
        var.gcp_ranges.gcp_prod_primary,
        var.gcp_ranges.gcp_prod_secondary,
      ]
    },
  ]
  nva_locality = {
    for v in setproduct(keys(var.regions), local.nva_zones) :
    join("-", v) => {
      name   = v[0]
      region = var.regions[v[0]]
      zone   = v[1]
    }
  }
  nva_zones = ["b", "c"]
}

# NVA config
module "nva-cloud-config" {
  source               = "../../../modules/cloud-config-container/simple-nva"
  enable_health_checks = true
  network_interfaces   = local.routing_config
}

module "nva-template" {
  for_each        = local.nva_locality
  source          = "../../../modules/compute-vm"
  project_id      = module.landing-project.project_id
  name            = "nva-template-${each.key}"
  zone            = "${each.value.region}-${each.value.zone}"
  instance_type   = "e2-standard-2"
  tags            = ["nva"]
  create_template = true
  can_ip_forward  = true
  network_interfaces = [
    {
      network = module.dmz-vpc.self_link
      subnetwork = try(
        module.dmz-vpc.subnet_self_links["${each.value.region}/dmz-default"], null
      )
      nat       = false
      addresses = null
    },
    {
      network = module.landing-vpc.self_link
      subnetwork = try(
        module.landing-vpc.subnet_self_links["${each.value.region}/landing-default"], null
      )
      nat       = false
      addresses = null
    }
  ]
  boot_disk = {
    initialize_params = {
      image = "projects/cos-cloud/global/images/family/cos-stable"
    }
  }
  options = {
    allow_stopping_for_update = true
    deletion_protection       = false
    spot                      = true
    termination_action        = "STOP"
  }
  metadata = {
    user-data = module.nva-cloud-config.cloud_config
  }
}

module "nva-mig" {
  for_each          = local.nva_locality
  source            = "../../../modules/compute-mig"
  project_id        = module.landing-project.project_id
  location          = each.value.region
  name              = "nva-cos-${each.key}"
  instance_template = module.nva-template[each.key].template.self_link
  target_size       = 1
  auto_healing_policies = {
    initial_delay_sec = 30
  }
  health_check_config = {
    enable_logging = true
    tcp = {
      port = 22
    }
  }
}

module "ilb-nva-dmz" {
  for_each = {
    for k, v in var.regions : k => {
      region = v
      subnet = "${v}/dmz-default"
    }
  }
  source        = "../../../modules/net-lb-int"
  project_id    = module.landing-project.project_id
  region        = each.value.region
  name          = "nva-dmz-${each.key}"
  service_label = var.prefix
  forwarding_rules_config = {
    "" = {
      global_access = true
    }
  }
  vpc_config = {
    network    = module.dmz-vpc.self_link
    subnetwork = try(module.dmz-vpc.subnet_self_links[each.value.subnet], null)
  }
  backends = [
    for k, v in module.nva-mig :
    { group = v.group_manager.instance_group }
    if startswith(k, each.key)
  ]
  health_check_config = {
    enable_logging = true
    tcp = {
      port = 22
    }
  }
}

module "ilb-nva-landing" {
  for_each = {
    for k, v in var.regions : k => {
      region = v
      subnet = "${v}/landing-default"
    }
  }
  source        = "../../../modules/net-lb-int"
  project_id    = module.landing-project.project_id
  region        = each.value.region
  name          = "nva-landing-${each.key}"
  service_label = var.prefix
  forwarding_rules_config = {
    "" = {
      global_access = true
    }
  }
  vpc_config = {
    network    = module.landing-vpc.self_link
    subnetwork = try(module.landing-vpc.subnet_self_links[each.value.subnet], null)
  }
  backends = [
    for k, v in module.nva-mig :
    { group = v.group_manager.instance_group }
    if startswith(k, each.key)
  ]
  health_check_config = {
    enable_logging = true
    tcp = {
      port = 22
    }
  }
}
