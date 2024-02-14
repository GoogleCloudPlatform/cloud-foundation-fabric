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
  _nva_zones = ["b", "c"]

  # The configurations used to create the NVA VMs.
  # 
  # Rendered as following:
  # nva_configs = {
  #   primary-b   = {...}
  #   primary-c   = {...}
  #   secondary-b = {...}
  #   secondary-c = {...}
  # }
  nva_configs = {
    for v in setproduct(keys(var.regions), local._nva_zones) :
    join("-", v) => {
      # Each NVA announces its trusted regional subnets
      announce-to-nva = upper(v.0)
      # NVAs in each region have their own ASN
      # and peer with cross-regional NVAs.
      asn_nva = (
        v.0 == "primary"
        ? var.ncc_asn.nva_primary
        : var.ncc_asn.nva_secondary
      )
      asn_nva_cross_region = (
        v.0 == "primary"
        ? var.ncc_asn.nva_secondary
        : var.ncc_asn.nva_primary
      )
      asn_trusted   = var.ncc_asn.trusted
      asn_untrusted = var.ncc_asn.untrusted
      # To guarantee traffic to remain symmetric,
      # NVAs need to advertise cross-region routes with a higher cost (10100)
      cost_primary                    = v.0 == "primary" ? "100" : "10100"
      cost_secondary                  = v.0 == "primary" ? "10100" : "100"
      gcp_dev_primary                 = var.gcp_ranges.gcp_dev_primary
      gcp_dev_secondary               = var.gcp_ranges.gcp_dev_secondary
      gcp_landing_trusted_primary     = var.gcp_ranges.gcp_landing_trusted_primary
      gcp_landing_trusted_secondary   = var.gcp_ranges.gcp_landing_trusted_secondary
      gcp_landing_untrusted_primary   = var.gcp_ranges.gcp_landing_untrusted_primary
      gcp_landing_untrusted_secondary = var.gcp_ranges.gcp_landing_untrusted_secondary
      gcp_prod_primary                = var.gcp_ranges.gcp_prod_primary
      gcp_prod_secondary              = var.gcp_ranges.gcp_prod_secondary
      # The IPs of cross-region NVA VMs in the untrusted VPC (x.y.w.z)
      ip_neighbor_cross_region_nva_0 = cidrhost(module.landing-untrusted-vpc.subnet_ips["${local._regions_cross[v.0]}/landing-untrusted-default-${local.region_shortnames[local._regions_cross[v.0]]}"], 101)
      ip_neighbor_cross_region_nva_1 = cidrhost(module.landing-untrusted-vpc.subnet_ips["${local._regions_cross[v.0]}/landing-untrusted-default-${local.region_shortnames[local._regions_cross[v.0]]}"], 102)
      # The Cloud router IPs (x.y.w.z) in the untrusted
      # and in the trusted VPCs, where the NVA connects to
      ip_neighbor_trusted_0   = cidrhost(module.landing-trusted-vpc.subnet_ips["${var.regions[v.0]}/landing-trusted-default-${local.region_shortnames[var.regions[v.0]]}"], 201)
      ip_neighbor_trusted_1   = cidrhost(module.landing-trusted-vpc.subnet_ips["${var.regions[v.0]}/landing-trusted-default-${local.region_shortnames[var.regions[v.0]]}"], 202)
      ip_neighbor_untrusted_0 = cidrhost(module.landing-untrusted-vpc.subnet_ips["${var.regions[v.0]}/landing-untrusted-default-${local.region_shortnames[var.regions[v.0]]}"], 201)
      ip_neighbor_untrusted_1 = cidrhost(module.landing-untrusted-vpc.subnet_ips["${var.regions[v.0]}/landing-untrusted-default-${local.region_shortnames[var.regions[v.0]]}"], 202)
      # The IPs to assign to the NVA NICs
      # in the trusted and in the untrusted VPCs.
      ip_trusted   = cidrhost(module.landing-trusted-vpc.subnet_ips["${var.regions[v.0]}/landing-trusted-default-${local.region_shortnames[var.regions[v.0]]}"], 101 + index(var.zones, v.1))
      ip_untrusted = cidrhost(module.landing-untrusted-vpc.subnet_ips["${var.regions[v.0]}/landing-untrusted-default-${local.region_shortnames[var.regions[v.0]]}"], 101 + index(var.zones, v.1))
      # Either primary or secondary
      name = v.0
      # The name of the region where the NVA lives.
      # For example, europe-west1 or europe-west4
      region = var.regions[v.0]
      # the short name for the region. For example, ew1 or ew4
      shortname = local.region_shortnames[var.regions[v.0]]
      # The zone where the NVA lives. For example, b or c
      zone = v.1
    }
  }

  # The routing_config should be aligned to the NVA NICs.
  # For example:
  # local.routing_config[0] configures eth0;
  # local.routing_config[0] configures eth1.
  routing_config = [
    {
      enable_masquerading = true
      name                = "untrusted"
      routes = [
        var.gcp_ranges.gcp_landing_untrusted_primary,
        var.gcp_ranges.gcp_landing_untrusted_secondary
      ]
    },
    {
      name = "trusted"
      routes = [
        var.gcp_ranges.gcp_landing_trusted_primary,
        var.gcp_ranges.gcp_landing_trusted_secondary
      ]
    }
  ]
}

module "nva-bgp-cloud-config" {
  for_each             = local.nva_configs
  source               = "../../../modules/cloud-config-container/simple-nva"
  enable_health_checks = true
  network_interfaces   = local.routing_config
  frr_config = {
    config_file     = templatefile("data/bgp-config.tftpl", each.value)
    daemons_enabled = ["bgpd"]
  }
}

resource "google_compute_address" "nva_static_ip_trusted" {
  for_each     = local.nva_configs
  name         = "nva-ip-trusted-${each.value.shortname}-${each.value.zone}"
  project      = module.landing-project.project_id
  subnetwork   = module.landing-trusted-vpc.subnet_self_links["${each.value.region}/landing-trusted-default-${each.value.shortname}"]
  address_type = "INTERNAL"
  address      = each.value.ip_trusted
  region       = each.value.region
}

resource "google_compute_address" "nva_static_ip_untrusted" {
  for_each     = local.nva_configs
  name         = "nva-ip-untrusted-${each.value.shortname}-${each.value.zone}"
  project      = module.landing-project.project_id
  subnetwork   = module.landing-untrusted-vpc.subnet_self_links["${each.value.region}/landing-untrusted-default-${each.value.shortname}"]
  address_type = "INTERNAL"
  address      = each.value.ip_untrusted
  region       = each.value.region
}

module "nva" {
  for_each       = local.nva_configs
  source         = "../../../modules/compute-vm"
  project_id     = module.landing-project.project_id
  name           = "nva-${each.value.shortname}-${each.value.zone}"
  instance_type  = "e2-standard-2"
  can_ip_forward = true
  zone           = "${each.value.region}-${each.value.zone}"
  tags           = ["nva"]

  network_interfaces = [
    {
      network    = module.landing-untrusted-vpc.self_link
      subnetwork = module.landing-untrusted-vpc.subnet_self_links["${each.value.region}/landing-untrusted-default-${each.value.shortname}"]
      nat        = false
      addresses = {
        internal = google_compute_address.nva_static_ip_untrusted[each.key].address
      }
    },
    {
      network    = module.landing-trusted-vpc.self_link
      subnetwork = module.landing-trusted-vpc.subnet_self_links["${each.value.region}/landing-trusted-default-${each.value.shortname}"]
      nat        = false
      addresses = {
        internal = google_compute_address.nva_static_ip_trusted[each.key].address
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
