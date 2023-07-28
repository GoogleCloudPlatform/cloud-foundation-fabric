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

resource "google_compute_router" "interconnect-router-primary" {
  name    = "interconnect-router-primary"
  project = module.net-project.project_id
  network = module.external-vpc.name
  region  = var.regions.primary
  bgp {
    asn               = 16550
    advertise_mode    = "CUSTOM"
    advertised_groups = []
    advertised_ip_ranges {
      range = var.gcp_ranges.gcp_all_primary
    }
    advertised_ip_ranges {
      range = var.gcp_ranges.gcp_all_secondary
    }
  }
}

resource "google_compute_router" "interconnect-router-secondary" {
  name    = "interconnect-router-secondary"
  project = module.net-project.project_id
  network = module.external-vpc.name
  region  = var.regions.secondary
  bgp {
    asn               = 16550
    advertise_mode    = "CUSTOM"
    advertised_groups = []
    advertised_ip_ranges {
      range = var.gcp_ranges.gcp_all_primary
    }
    advertised_ip_ranges {
      range = var.gcp_ranges.gcp_all_secondary
    }
  }
}

module "primary-a-vlan-attachment" {
  source      = "../../../modules/net-vlan-attachment"
  project_id  = module.net-project.project_id
  network     = module.external-vpc.name
  region      = var.regions.primary
  name        = "primary-a"
  description = "primary vlan attachment a"
  peer_asn    = "65000"
  router_config = {
    create = false
    name   = google_compute_router.interconnect-router-primary.name
  }
  partner_interconnect_config = {
    edge_availability_domain = "AVAILABILITY_DOMAIN_1"
  }
}

module "primary-b-vlan-attachment" {
  source      = "../../../modules/net-vlan-attachment"
  project_id  = module.net-project.project_id
  network     = module.external-vpc.name
  region      = var.regions.primary
  name        = "primary-b"
  description = "primary vlan attachment b"
  peer_asn    = "65000"
  router_config = {
    create = false
    name   = google_compute_router.interconnect-router-primary.name
  }
  partner_interconnect_config = {
    edge_availability_domain = "AVAILABILITY_DOMAIN_2"
  }
}

module "secondary-a-vlan-attachment" {
  source      = "../../../modules/net-vlan-attachment"
  project_id  = module.net-project.project_id
  network     = module.external-vpc.name
  region      = var.regions.secondary
  name        = "secondary-a"
  description = "secondary vlan attachment a"
  peer_asn    = "65000"
  router_config = {
    create = false
    name   = google_compute_router.interconnect-router-secondary.name
  }
  partner_interconnect_config = {
    edge_availability_domain = "AVAILABILITY_DOMAIN_1"
  }
}

module "secondary-b-vlan-attachment" {
  source      = "../../../modules/net-vlan-attachment"
  project_id  = module.net-project.project_id
  network     = module.external-vpc.name
  region      = var.regions.secondary
  name        = "secondary-b"
  description = "secondary vlan attachment b"
  peer_asn    = "65000"
  router_config = {
    create = false
    name   = google_compute_router.interconnect-router-secondary.name
  }
  partner_interconnect_config = {
    edge_availability_domain = "AVAILABILITY_DOMAIN_2"
  }
}

