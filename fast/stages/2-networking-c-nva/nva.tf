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
      name                = "untrusted"
      enable_masquerading = true
      routes = [
        var.gcp_ranges.gcp_landing_untrusted_primary,
        var.gcp_ranges.gcp_landing_untrusted_secondary,
      ]
    },
    {
      name = "trusted"
      routes = [
        var.gcp_ranges.gcp_dev_primary,
        var.gcp_ranges.gcp_dev_secondary,
        var.gcp_ranges.gcp_landing_trusted_primary,
        var.gcp_ranges.gcp_landing_trusted_secondary,
        var.gcp_ranges.gcp_prod_primary,
        var.gcp_ranges.gcp_prod_secondary,
      ]
    },
  ]
  nva_locality = {
    for v in setproduct(keys(var.regions), local.nva_zones) :
    join("-", v) => {
      name      = v.0
      region    = var.regions[v.0]
      shortname = local.region_shortnames[var.regions[v.0]]
      zone      = v.1
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
      network    = module.landing-untrusted-vpc.self_link
      subnetwork = module.landing-untrusted-vpc.subnet_self_links["${each.value.region}/landing-untrusted-default-${each.value.shortname}"]
      nat        = false
      addresses  = null
    },
    {
      network    = module.landing-trusted-vpc.self_link
      subnetwork = module.landing-trusted-vpc.subnet_self_links["${each.value.region}/landing-trusted-default-${each.value.shortname}"]
      nat        = false
      addresses  = null
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

module "ilb-nva-untrusted" {
  for_each = {
    for k, v in var.regions : k => {
      region    = v
      shortname = local.region_shortnames[v]
      subnet    = "${v}/landing-untrusted-default-${local.region_shortnames[v]}"
    }
  }
  source        = "../../../modules/net-lb-int"
  project_id    = module.landing-project.project_id
  region        = each.value.region
  name          = "nva-untrusted-${each.key}"
  service_label = var.prefix
  forwarding_rules_config = {
    "" = {
      global_access = true
    }
  }
  vpc_config = {
    network    = module.landing-untrusted-vpc.self_link
    subnetwork = module.landing-untrusted-vpc.subnet_self_links[each.value.subnet]
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

module "ilb-nva-trusted" {
  for_each = {
    for k, v in var.regions : k => {
      region    = v
      shortname = local.region_shortnames[v]
      subnet    = "${v}/landing-trusted-default-${local.region_shortnames[v]}"
    }
  }
  source        = "../../../modules/net-lb-int"
  project_id    = module.landing-project.project_id
  region        = each.value.region
  name          = "nva-trusted-${each.key}"
  service_label = var.prefix
  forwarding_rules_config = {
    "" = {
      global_access = true
    }
  }
  vpc_config = {
    network    = module.landing-trusted-vpc.self_link
    subnetwork = module.landing-trusted-vpc.subnet_self_links[each.value.subnet]
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
