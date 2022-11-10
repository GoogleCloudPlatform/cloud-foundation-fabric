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
#                        Host project and VPC resources                       #
###############################################################################

module "project" {
  source          = "../../../modules/project"
  project_create  = var.project_create != null
  billing_account = try(var.project_create.billing_account, null)
  parent          = try(var.project_create.parent, null)
  name            = var.project_id
  services = [
    "dns.googleapis.com",
    "compute.googleapis.com",
    "logging.googleapis.com"
  ]
}

module "vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.project.project_id
  name       = "${var.prefix}-vpc"
  subnets = [
    {
      name          = "proxy"
      ip_cidr_range = var.cidrs.proxy
      region        = var.region
    }
  ]
  subnets_psc = [
    {
      name          = "psc"
      ip_cidr_range = var.cidrs.psc
      region        = var.region
    }
  ]
}

module "firewall" {
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.project.project_id
  network    = module.vpc.name
  ingress_rules = {
    allow-ingress-squid = {
      description = "Allow squid ingress traffic"
      source_ranges = [
        var.cidrs.psc, "35.191.0.0/16", "130.211.0.0/22"
      ]
      targets              = [module.service-account-squid.email]
      use_service_accounts = true
      rules = [{
        protocol = "tcp"
        ports    = [3128]
      }]
    }
  }
}

module "nat" {
  source                = "../../../modules/net-cloudnat"
  project_id            = module.project.project_id
  region                = var.region
  name                  = "default"
  router_network        = module.vpc.name
  config_source_subnets = "LIST_OF_SUBNETWORKS"
  # 64512/11 = 5864 . 11 is the number of usable IPs in the proxy subnet
  config_min_ports_per_vm = 5864
  subnetworks = [
    {
      self_link            = module.vpc.subnet_self_links["${var.region}/proxy"]
      config_source_ranges = ["ALL_IP_RANGES"]
      secondary_ranges     = null
    }
  ]
  logging_filter = var.nat_logging
}

###############################################################################
#                              PSC resources                                  #
###############################################################################

resource "google_compute_service_attachment" "service_attachment" {
  name                  = "psc"
  project               = module.project.project_id
  region                = var.region
  enable_proxy_protocol = false
  connection_preference = "ACCEPT_MANUAL"
  nat_subnets           = [module.vpc.subnets_psc["${var.region}/psc"].self_link]
  target_service        = module.squid-ilb.forwarding_rule_self_link
  consumer_accept_lists {
    project_id_or_num = module.project.project_id
    connection_limit  = 10
  }
}

###############################################################################
#                               Squid resources                               #
###############################################################################

module "service-account-squid" {
  source     = "../../../modules/iam-service-account"
  project_id = module.project.project_id
  name       = "svc-squid"
  iam_project_roles = {
    (module.project.project_id) = [
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
    ]
  }
}

module "cos-squid" {
  source  = "../../../modules/cloud-config-container/squid"
  allow   = var.allowed_domains
  clients = [var.cidrs.psc]
}

module "squid-vm" {
  source          = "../../../modules/compute-vm"
  project_id      = module.project.project_id
  zone            = "${var.region}-b"
  name            = "squid-vm"
  instance_type   = "e2-medium"
  create_template = true
  network_interfaces = [{
    network    = module.vpc.self_link
    subnetwork = module.vpc.subnet_self_links["${var.region}/proxy"]
  }]
  boot_disk = {
    image = "cos-cloud/cos-stable"
  }
  service_account        = module.service-account-squid.email
  service_account_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  metadata = {
    user-data = module.cos-squid.cloud_config
  }
}

module "squid-mig" {
  source            = "../../../modules/compute-mig"
  project_id        = module.project.project_id
  location          = "${var.region}-b"
  name              = "squid-mig"
  instance_template = module.squid-vm.template.self_link
  target_size       = 1
  auto_healing_policies = {
    initial_delay_sec = 60
  }
  autoscaler_config = {
    max_replicas    = 10
    min_replicas    = 1
    cooldown_period = 30
    scaling_signals = {
      cpu_utilization = {
        target = 0.65
      }
    }
  }
  health_check_config = {
    enable_logging = true
    tcp = {
      port = 3128
    }
  }
  update_policy = {
    minimal_action = "REPLACE"
    type           = "PROACTIVE"
    max_surge = {
      fixed = 3
    }
    min_ready_sec = 60
  }
}

module "squid-ilb" {
  source        = "../../../modules/net-ilb"
  project_id    = module.project.project_id
  region        = var.region
  name          = "squid-ilb"
  ports         = [3128]
  service_label = "squid-ilb"
  vpc_config = {
    network    = module.vpc.self_link
    subnetwork = module.vpc.subnet_self_links["${var.region}/proxy"]
  }
  backends = [{
    group = module.squid-mig.group_manager.instance_group
  }]
  health_check_config = {
    enable_logging = true
    tcp = {
      port = 3128
    }
  }
}

###############################################################################
#                          Consumer project and VPC                           #
###############################################################################

module "vpc-consumer" {
  source     = "../../../modules/net-vpc"
  project_id = module.project.project_id
  name       = "${var.prefix}-app"
  subnets = [
    {
      name          = "${var.prefix}-app"
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
  name          = "${var.prefix}-test-vm"
  instance_type = "e2-micro"
  tags          = ["ssh"]
  network_interfaces = [{
    network    = module.vpc-consumer.self_link
    subnetwork = module.vpc-consumer.subnet_self_links["${var.region}/${var.prefix}-app"]
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
  project      = module.project.project_id
  address_type = "INTERNAL"
  subnetwork   = module.vpc-consumer.subnet_self_links["${var.region}/${var.prefix}-app"]
  region       = var.region
}

resource "google_compute_forwarding_rule" "psc_ilb_consumer" {
  name                  = "${var.prefix}-psc-proxy-fw-rule"
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
  name            = "${var.prefix}-internal"
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
