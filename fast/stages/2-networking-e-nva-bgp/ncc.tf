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

resource "google_network_connectivity_hub" "hub_trusted" {
  name        = "prod-hub-trusted"
  description = "Prod hub trusted"
  project     = module.landing-project.project_id
}

resource "google_network_connectivity_hub" "hub_untrusted" {
  name        = "prod-hub-untrusted"
  description = "Prod hub untrusted"
  project     = module.landing-project.project_id
}

module "spokes-trusted" {
  for_each   = var.regions
  source     = "../../../modules/ncc-spoke-ra"
  name       = "prod-spoke-trusted-${local.region_shortnames[each.value]}"
  project_id = module.landing-project.project_id
  region     = each.value

  hub = {
    create = false,
    id     = google_network_connectivity_hub.hub_trusted.id
  }

  router_appliances = [
    for key, config in local.nva_configs :
    {
      internal_ip  = module.nva[key].internal_ips[1]
      vm_self_link = module.nva[key].self_link
    } if config.region == each.value
  ]

  router_config = {
    asn           = var.ncc_asn.trusted
    ip_interface0 = cidrhost(module.landing-trusted-vpc.subnet_ips["${each.value}/landing-trusted-default-${local.region_shortnames[each.value]}"], 201)
    ip_interface1 = cidrhost(module.landing-trusted-vpc.subnet_ips["${each.value}/landing-trusted-default-${local.region_shortnames[each.value]}"], 202)
    peer_asn = (
      each.key == "primary"
      ? var.ncc_asn.nva_primary
      : var.ncc_asn.nva_secondary
    )
    routes_priority = 100

    custom_advertise = {
      all_subnets = false
      ip_ranges = {
        "${var.gcp_ranges.gcp_landing_trusted_primary}"   = "GCP landing trusted primary."
        "${var.gcp_ranges.gcp_landing_trusted_secondary}" = "GCP landing trusted secondary."
        "${var.gcp_ranges.gcp_dev_primary}"               = "GCP dev primary.",
        "${var.gcp_ranges.gcp_dev_secondary}"             = "GCP dev secondary.",
        "${var.gcp_ranges.gcp_prod_primary}"              = "GCP prod primary.",
        "${var.gcp_ranges.gcp_prod_secondary}"            = "GCP prod secondary.",
      }
    }
  }

  vpc_config = {
    network_name     = module.landing-trusted-vpc.self_link
    subnet_self_link = module.landing-trusted-vpc.subnet_self_links["${each.value}/landing-trusted-default-${local.region_shortnames[each.value]}"]
  }
}

module "spokes-untrusted" {
  for_each   = var.regions
  source     = "../../../modules/ncc-spoke-ra"
  name       = "prod-spoke-untrusted-${local.region_shortnames[each.value]}"
  project_id = module.landing-project.project_id
  region     = each.value

  hub = {
    create = false,
    id     = google_network_connectivity_hub.hub_untrusted.id
  }

  router_appliances = [
    for key, config in local.nva_configs :
    {
      internal_ip  = module.nva[key].internal_ips[0]
      vm_self_link = module.nva[key].self_link
    } if config.region == each.value
  ]

  router_config = {
    asn           = var.ncc_asn.untrusted
    ip_interface0 = cidrhost(module.landing-untrusted-vpc.subnet_ips["${each.value}/landing-untrusted-default-${local.region_shortnames[each.value]}"], 201)
    ip_interface1 = cidrhost(module.landing-untrusted-vpc.subnet_ips["${each.value}/landing-untrusted-default-${local.region_shortnames[each.value]}"], 202)
    peer_asn = (
      each.key == "primary"
      ? var.ncc_asn.nva_primary
      : var.ncc_asn.nva_secondary
    )
    routes_priority = 100

    custom_advertise = {
      all_subnets = false
      ip_ranges   = { "0.0.0.0/0" = "Default route." }
    }
  }

  vpc_config = {
    network_name     = module.landing-untrusted-vpc.self_link
    subnet_self_link = module.landing-untrusted-vpc.subnet_self_links["${each.value}/landing-untrusted-default-${local.region_shortnames[each.value]}"]
  }
}
