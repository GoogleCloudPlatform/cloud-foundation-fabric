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
  _routing_config = [
    {
      name                = "dmz"
      enable_masquerading = true
      routes = [
        var.gcp_ranges.gcp_dmz_primary,
        var.gcp_ranges.gcp_dmz_secondary,
      ]
    },
    {
      name = "external"
      routes = [
        var.gcp_ranges.gcp_external_primary,
        var.gcp_ranges.gcp_external_secondary,
        var.gcp_ranges.onprem_range_10
      ]
    },
    {
      name = "mgmt"
      routes = [
        var.gcp_ranges.gcp_mgmt_primary,
        var.gcp_ranges.gcp_mgmt_secondary,
      ]
    },
    {
      name = "shared"
      routes = [
        var.gcp_ranges.gcp_shared_primary,
        var.gcp_ranges.gcp_shared_secondary
      ]
    },
  ]
  routing_config_primary = concat(local._routing_config, [
    {
      name = "transit_primary"
      routes = [
        var.gcp_ranges.gcp_transit_primary
      ]
    }
  ])
  zones = ["a", "c"]
}

# NVA config
module "nva-cloud-config-primary" {
  source               = "../../../modules/cloud-config-container/simple-nva"
  enable_health_checks = true
  network_interfaces   = local.routing_config_primary
}

module "nva-primary" {
  for_each       = toset(local.zones)
  source         = "../../../modules/compute-vm"
  project_id     = module.net-project.project_id
  name           = "nva-primary-${each.key}"
  zone           = "${var.regions.primary}-${each.key}"
  instance_type  = "e2-standard-8"
  tags           = ["nva"]
  can_ip_forward = true
  network_interfaces = [
    {
      network    = module.dmz-vpc.self_link
      subnetwork = module.dmz-vpc.subnet_self_links["${var.regions.primary}/prod-core-dmz-0-nva-primary"]
      nat        = false
      addresses  = null
    },
    {
      network    = module.external-vpc.self_link
      subnetwork = module.external-vpc.subnet_self_links["${var.regions.primary}/prod-core-external-0-nva-primary"]
      nat        = false
      addresses  = null
    },
    {
      network    = module.mgmt-vpc.self_link
      subnetwork = module.mgmt-vpc.subnet_self_links["${var.regions.primary}/prod-core-mgmt-0-nva-primary"]
      nat        = false
      addresses  = null
    },
    {
      network    = module.shared-vpc.self_link
      subnetwork = module.shared-vpc.subnet_self_links["${var.regions.primary}/prod-core-shared-0-nva-primary"]
      nat        = false
      addresses  = null
    },
    {
      network    = module.transit-primary-vpc.self_link
      subnetwork = module.transit-primary-vpc.subnet_self_links["${var.regions.primary}/prod-core-transit-primary-0-nva"]
      nat        = false
      addresses  = null
    },
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
    user-data = module.nva-cloud-config-primary.cloud_config
  }
}

resource "google_compute_instance_group" "nva-primary" {
  for_each    = toset(local.zones)
  name        = "nva-primary-ig-${each.key}"
  description = "NVA instance group for the primary region, zone ${each.key}."
  zone        = "${var.regions.primary}-${each.key}"
  project     = module.net-project.project_id
  network     = module.dmz-vpc.self_link
  instances   = toset([module.nva-primary[each.key].self_link])
}


# # module "ilb-nva-untrusted" {
# #   for_each = {
# #     for k, v in var.regions : k => {
# #       region    = v
# #       shortname = local.region_shortnames[v]
# #       subnet    = "${v}/external-default-${local.region_shortnames[v]}"
# #     }
# #   }
# #   source        = "../../../modules/net-lb-int"
# #   project_id    = module.net-project.project_id
# #   region        = each.value.region
# #   name          = "nva-untrusted-${each.key}"
# #   service_label = var.prefix
# #   global_access = true
# #   vpc_config = {
# #     network    = module.external-vpc.self_link
# #     subnetwork = module.external-vpc.subnet_self_links[each.value.subnet]
# #   }
# #   backends = [
# #     for k, v in module.nva-mig :
# #     { group = v.group_manager.instance_group }
# #     if startswith(k, each.key)
# #   ]
# #   health_check_config = {
# #     enable_logging = true
# #     tcp = {
# #       port = 22
# #     }
# #   }
# # }
