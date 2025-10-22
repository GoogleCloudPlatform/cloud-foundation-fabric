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

locals {
  # The configurations used to create the NVA VMs.
  #
  # Rendered as following:
  # bgp_nva_configs = {
  #   primary-b   = {...}
  #   primary-c   = {...}
  #   secondary-b = {...}
  #   secondary-c = {...}
  # }
  bgp_nva_configs = {
    for v in setproduct(keys(var.regions), local.nva_zones) :
    join("-", v) => {
      # Each NVA announces its trusted regional subnets
      announce-to-nva = upper(v[0])
      # NVAs in each region have their own ASN
      # and peer with cross-regional NVAs.
      asn_nva = (
        v[0] == "primary"
        ? local.ncc_asn.nva_primary
        : local.ncc_asn.nva_secondary
      )
      asn_nva_cross_region = (
        v[0] == "primary"
        ? local.ncc_asn.nva_secondary
        : local.ncc_asn.nva_primary
      )
      asn_landing = local.ncc_asn.landing
      asn_dmz     = local.ncc_asn.dmz
      # To guarantee traffic to remain symmetric,
      # NVAs need to advertise cross-region routes with a higher cost (10100)
      cost_primary                  = v[0] == "primary" ? "100" : "10100"
      cost_secondary                = v[0] == "primary" ? "10100" : "100"
      gcp_dev_primary               = var.gcp_ranges.gcp_dev_primary
      gcp_dev_secondary             = var.gcp_ranges.gcp_dev_secondary
      gcp_landing_landing_primary   = var.gcp_ranges.gcp_landing_primary
      gcp_landing_landing_secondary = var.gcp_ranges.gcp_landing_secondary
      gcp_landing_dmz_primary       = var.gcp_ranges.gcp_dmz_primary
      gcp_landing_dmz_secondary     = var.gcp_ranges.gcp_dmz_secondary
      gcp_prod_primary              = var.gcp_ranges.gcp_prod_primary
      gcp_prod_secondary            = var.gcp_ranges.gcp_prod_secondary
      # The IPs of cross-region NVA VMs in the DMZ VPC (x.y.w.z)
      ip_neighbor_cross_region_nva_0 = cidrhost(
        module.dmz-vpc.subnet_ips["${local._regions_cross[v[0]]}/dmz-default"], 101
      )
      ip_neighbor_cross_region_nva_1 = cidrhost(
        module.dmz-vpc.subnet_ips["${local._regions_cross[v[0]]}/dmz-default"], 102
      )
      # The Cloud router IPs (x.y.w.z) in the DMZ
      # and in the landing VPCs, where the NVA connects to
      ip_neighbor_landing_0 = cidrhost(
        module.landing-vpc.subnet_ips["${var.regions[v[0]]}/landing-default"], 201
      )
      ip_neighbor_landing_1 = cidrhost(
        module.landing-vpc.subnet_ips["${var.regions[v[0]]}/landing-default"], 202
      )
      ip_neighbor_dmz_0 = cidrhost(
        module.dmz-vpc.subnet_ips["${var.regions[v[0]]}/dmz-default"], 201
      )
      ip_neighbor_dmz_1 = cidrhost(
        module.dmz-vpc.subnet_ips["${var.regions[v[0]]}/dmz-default"], 202
      )
      # The IPs to assign to the NVA NICs
      # in the landing and in the DMZ VPCs.
      ip_landing = cidrhost(
        module.landing-vpc.subnet_ips["${var.regions[v[0]]}/landing-default"],
        101 + index(local.nva_zones, v[1])
      )
      ip_dmz = cidrhost(
        module.dmz-vpc.subnet_ips["${var.regions[v[0]]}/dmz-default"],
        101 + index(local.nva_zones, v[1])
      )
      # Either primary or secondary
      name = v[0]
      # The name of the region where the NVA lives.
      # For example, europe-west1 or europe-west4
      region = var.regions[v[0]]
      # the short name for the region. For example, ew1 or ew4
      shortname = local.region_shortnames[var.regions[v[0]]]
      # The zone where the NVA lives. For example, b or c
      zone = v[1]
    }
  }

  # The bgp_routing_config should be aligned to the NVA NICs.
  # For example:
  # local.bgp_routing_config[0] configures eth0;
  # local.bgp_routing_config[0] configures eth1.
  bgp_routing_config = [
    {
      enable_masquerading = true
      name                = "dmz"
      routes = [
        var.gcp_ranges.gcp_dmz_primary,
        var.gcp_ranges.gcp_dmz_secondary
      ]
    },
    {
      name = "landing"
      routes = [
        var.gcp_ranges.gcp_landing_primary,
        var.gcp_ranges.gcp_landing_secondary
      ]
    }
  ]
}

module "nva-bgp-cloud-config" {
  for_each             = (var.network_mode == "ncc_ra") ? local.bgp_nva_configs : {}
  source               = "../../../modules/cloud-config-container/simple-nva"
  enable_health_checks = true
  network_interfaces   = local.bgp_routing_config
  frr_config = {
    config_file     = templatefile("data/bgp-config.tftpl", each.value)
    daemons_enabled = ["bgpd"]
  }
}

# TODO: use address module

resource "google_compute_address" "nva_static_ip_landing" {
  for_each     = (var.network_mode == "ncc_ra") ? local.bgp_nva_configs : {}
  name         = "nva-ip-landing-${each.value.shortname}-${each.value.zone}"
  project      = module.landing-project.project_id
  subnetwork   = module.landing-vpc.subnet_self_links["${each.value.region}/landing-default"]
  address_type = "INTERNAL"
  address      = each.value.ip_landing
  region       = each.value.region
}

resource "google_compute_address" "nva_static_ip_dmz" {
  for_each     = (var.network_mode == "ncc_ra") ? local.bgp_nva_configs : {}
  name         = "nva-ip-dmz-${each.value.shortname}-${each.value.zone}"
  project      = module.landing-project.project_id
  subnetwork   = module.dmz-vpc.subnet_self_links["${each.value.region}/dmz-default"]
  address_type = "INTERNAL"
  address      = each.value.ip_dmz
  region       = each.value.region
}

module "nva-bgp" {
  for_each       = (var.network_mode == "ncc_ra") ? local.bgp_nva_configs : {}
  source         = "../../../modules/compute-vm"
  project_id     = module.landing-project.project_id
  name           = "nva-${each.value.shortname}-${each.value.zone}"
  instance_type  = "e2-micro"
  can_ip_forward = true
  zone           = "${each.value.region}-${each.value.zone}"
  tags           = ["nva"]

  network_interfaces = [
    {
      network    = module.dmz-vpc.self_link
      subnetwork = module.dmz-vpc.subnet_self_links["${each.value.region}/dmz-default"]
      nat        = false
      addresses = {
        internal = google_compute_address.nva_static_ip_dmz[each.key].address
      }
    },
    {
      network    = module.landing-vpc.self_link
      subnetwork = module.landing-vpc.subnet_self_links["${each.value.region}/landing-default"]
      nat        = false
      addresses = {
        internal = google_compute_address.nva_static_ip_landing[each.key].address
      }
    }
  ]

  boot_disk = {
    initialize_params = {
      image = "projects/cos-cloud/global/images/family/cos-stable"
      size  = 10
      type  = "pd-balanced"
    }
  }

  options = {
    allow_stopping_for_update = true
    deletion_protection       = false
    termination_action        = "STOP"
  }

  metadata = {
    user-data = module.nva-bgp-cloud-config[each.key].cloud_config
  }
}
