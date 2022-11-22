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

module "vpc-consumer" {
  source     = "../../../modules/net-vpc"
  project_id = module.project.project_id
  name       = "${local.prefix}app"
  subnets = [
    {
      name          = "${local.prefix}app"
      ip_cidr_range = var.cidrs.app
      region        = var.region
    }
  ]
}

###############################################################################
#                                   Test VM                                   #
###############################################################################

module "test-vm-consumer" {
  source        = "../../../modules/compute-vm"
  project_id    = module.project.project_id
  zone          = "${var.region}-b"
  name          = "${local.prefix}test-vm"
  instance_type = "e2-micro"
  tags          = ["ssh"]
  network_interfaces = [{
    network    = module.vpc-consumer.self_link
    subnetwork = module.vpc-consumer.subnet_self_links["${var.region}/${local.prefix}app"]
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
  name         = "${local.prefix}psc-proxy-address"
  project      = module.project.project_id
  address_type = "INTERNAL"
  subnetwork   = module.vpc-consumer.subnet_self_links["${var.region}/${local.prefix}app"]
  region       = var.region
}

resource "google_compute_forwarding_rule" "psc_ilb_consumer" {
  name                  = "${local.prefix}psc-proxy-fw-rule"
  project               = module.project.project_id
  region                = var.region
  target                = google_compute_service_attachment.service_attachment.id
  load_balancing_scheme = ""
  network               = module.vpc-consumer.self_link
  ip_address            = google_compute_address.psc_endpoint_address.id
}

###############################################################################
#                                DNS and Firewall                             #
###############################################################################

module "private-dns" {
  source          = "../../../modules/dns"
  project_id      = module.project.project_id
  type            = "private"
  name            = "${local.prefix}internal"
  domain          = "internal."
  client_networks = [module.vpc-consumer.self_link]
  recordsets = {
    "A squid"     = { ttl = 60, records = [google_compute_address.psc_endpoint_address.address] }
    "CNAME proxy" = { ttl = 3600, records = ["squid.internal."] }
  }
}

module "firewall-consumer" {
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.project.project_id
  network    = module.vpc-consumer.name
}
