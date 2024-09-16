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
  # local.simple_routing_config[0] sets up the first interface, and so on.
  regional_vpc_routing_config = {
    dmz-pri = {
      name                = "dmz-pri"
      enable_masquerading = true
      routes = [
        var.gcp_ranges.gcp_dmz_primary,
        var.gcp_ranges.gcp_dmz_secondary,
        var.gcp_ranges.gcp_regional_vpc_secondary
      ]
    },
    dmz-sec = {
      name                = "dmz-sec"
      enable_masquerading = true
      routes = [
        var.gcp_ranges.gcp_dmz_primary,
        var.gcp_ranges.gcp_dmz_secondary,
        var.gcp_ranges.gcp_regional_vpc_primary
      ]
    },
    landing = {
      name = "landing"
      routes = [
        var.gcp_ranges.gcp_dev_primary,
        var.gcp_ranges.gcp_dev_secondary,
        var.gcp_ranges.gcp_landing_primary,
        var.gcp_ranges.gcp_landing_secondary,
        var.gcp_ranges.gcp_prod_primary,
        var.gcp_ranges.gcp_prod_secondary,
      ]
    },
    regional-vpc-pri = {
      name = "regional-vpc-pri"
      routes = [
        var.gcp_ranges.gcp_regional_vpc_primary
      ]
    },
    regional-vpc-sec = {
      name = "regional-vpc-sec"
      routes = [
        var.gcp_ranges.gcp_regional_vpc_secondary
      ]
    }
  }
}

# NVA config
module "nva-regional-cloud-config" {
  for_each             = (var.network_mode == "regional_vpc") ? var.regions : {}
  source               = "../../../modules/cloud-config-container/simple-nva"
  enable_health_checks = true
  network_interfaces = concat(
    [each.key == "primary" ? local.regional_vpc_routing_config.dmz-pri : local.regional_vpc_routing_config.dmz-sec],
    [local.regional_vpc_routing_config.landing],
    [each.key == "primary" ? local.regional_vpc_routing_config.regional-vpc-pri : local.regional_vpc_routing_config.regional-vpc-sec]
  )
}


module "nva-regional-template" {
  for_each        = (var.network_mode == "regional_vpc") ? var.regions : {}
  source          = "../../../modules/compute-vm"
  project_id      = module.landing-project.project_id
  name            = "nva-regional-template-${each.key}"
  zone            = "${each.value}-${local.nva_zones[0]}"
  instance_type   = "e2-standard-4"
  tags            = ["nva"]
  create_template = true
  can_ip_forward  = true
  network_interfaces = [
    {
      network = module.dmz-vpc.self_link
      subnetwork = try(
        module.dmz-vpc.subnet_self_links["${each.value}/dmz-default"], null
      )
      nat       = false
      addresses = null
    },
    {
      network = module.landing-vpc.self_link
      subnetwork = try(
        module.landing-vpc.subnet_self_links["${each.value}/landing-default"], null
      )
      nat       = false
      addresses = null
    },
    ((each.key == "primary") ? #Select the Right VPC con the basis of locality
      {
        network = module.regional-primary-vpc[0].self_link
        subnetwork = try(
          module.regional-primary-vpc[0].subnet_self_links["${each.value}/regional-default"], null
        )
        nat       = false
        addresses = null
      }
      :
      {
        network = module.regional-secondary-vpc[0].self_link
        subnetwork = try(
          module.regional-secondary-vpc[0].subnet_self_links["${each.value}/regional-default"], null
        )
        nat       = false
        addresses = null
    })
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
    user-data = module.nva-regional-cloud-config[each.key].cloud_config
  }
}

module "nva-regional-mig" {
  for_each          = (var.network_mode == "regional_vpc") ? local.nva_locality : {}
  source            = "../../../modules/compute-mig"
  project_id        = module.landing-project.project_id
  location          = "${each.value.region}-${each.value.zone}"
  name              = "nva-cos-${each.key}"
  instance_template = module.nva-regional-template[each.value.name].template.self_link
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

module "ilb-regional-nva-dmz" {
  for_each = (var.network_mode == "regional_vpc") ? {
    for k, v in var.regions : k => {
      region = v
      subnet = "${v}/dmz-default"
    }
  } : {}
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
    for k, v in module.nva-regional-mig :
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

module "ilb-regional-nva-landing" {
  for_each = (var.network_mode == "regional_vpc") ? {
    for k, v in var.regions : k => {
      region = v
      subnet = "${v}/landing-default"
    }
  } : {}
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
    for k, v in module.nva-regional-mig :
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

module "ilb-regional-nva-regional-vpc" {
  for_each = (var.network_mode == "regional_vpc") ? {
    for k, v in var.regions : k => {
      region = v
      subnet = "${v}/regional-default"
    }
  } : {}
  source        = "../../../modules/net-lb-int"
  project_id    = module.landing-project.project_id
  region        = each.value.region
  name          = "nva-regional-${each.key}"
  service_label = var.prefix
  forwarding_rules_config = {
    "" = {
      global_access = true
    }
  }
  vpc_config = (each.key == "primary") ? {
    network    = module.regional-primary-vpc[0].self_link
    subnetwork = try(module.regional-primary-vpc[0].subnet_self_links[each.value.subnet], null)
    } : {
    network    = module.regional-secondary-vpc[0].self_link
    subnetwork = try(module.regional-secondary-vpc[0].subnet_self_links[each.value.subnet], null)
  }

  backends = [
    for k, v in module.nva-regional-mig :
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
