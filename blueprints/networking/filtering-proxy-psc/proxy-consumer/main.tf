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

###############################################################################
#                          Consumer project and VPC                           #
###############################################################################

module "vpc" {
  source     = "../../../../modules/net-vpc"
  project_id = var.project_id
  name       = "${var.prefix}-app"
  subnets = [
    {
      name          = "${var.prefix}-app"
      ip_cidr_range = var.subnet_cidr
      region        = var.region
    }
  ]
}

###############################################################################
#                                   Test VM                                   #
###############################################################################

module "test-vm" {
  source        = "../../../../modules/compute-vm"
  project_id    = var.project_id
  zone          = "${var.region}-b"
  name          = "${var.prefix}-test-vm"
  instance_type = "e2-micro"
  tags          = ["ssh"]
  network_interfaces = [{
    network    = module.vpc.self_link
    subnetwork = module.vpc.subnet_self_links["${var.region}/${var.prefix}-app"]
    nat        = false
    addresses  = null
  }]
  boot_disk = {
    image = "debian-cloud/debian-10"
    type  = "pd-standard"
    size  = 10
  }
  service_account_create = true
  metadata = {
    startup-script = templatefile("${path.module}/startup.sh", { proxy_url = "http://proxy.internal:3128" })
  }
}

###############################################################################
#                                 PSC Consuner                                #
###############################################################################

resource "google_compute_address" "psc_endpoint_address" {
  name         = "${var.prefix}-psc-proxy-address"
  project      = var.project_id
  address_type = "INTERNAL"
  subnetwork   = module.vpc.subnet_self_links["${var.region}/${var.prefix}-app"]
  region       = var.region
}

resource "google_compute_forwarding_rule" "psc_ilb_consumer" {
  name                  = "${var.prefix}-psc-proxy-fw-rule"
  project               = var.project_id
  region                = var.region
  target                = var.service_attachment_id
  load_balancing_scheme = ""
  network               = module.vpc.self_link
  ip_address            = google_compute_address.psc_endpoint_address.id
}

###############################################################################
#                                DNS and Firewall                             #
###############################################################################

module "private-dns" {
  source          = "../../../../modules/dns"
  project_id      = var.project_id
  type            = "private"
  name            = "${var.prefix}-internal"
  domain          = "internal."
  client_networks = [module.vpc.self_link]
  recordsets = {
    "A squid"     = { ttl = 60, records = [google_compute_address.psc_endpoint_address.address] }
    "CNAME proxy" = { ttl = 3600, records = ["squid.internal."] }
  }
}

module "firewall" {
  source     = "../../../../modules/net-vpc-firewall"
  project_id = var.project_id
  network    = module.vpc.name
}
