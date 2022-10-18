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

  vpcs = {
    "producer" = {
      proxies = "172.16.0.0/29"
      service = "10.0.0.0/24"
    }
    "consumer" = {
      proxies = "172.16.1.0/29"
      client  = "10.1.0.0/24"
    }
  }

  envoy_ilb_consumer_address = "172.16.1.2"

  zones = { for z in var.zones : z => "${var.region}-${z}" }

  services = {
    "svc-1" = {
      frontend = {
        address = "192.168.1.1"
        port    = 443
      }
      backend = {
        address = "10.0.0.2"
        port    = 443
      }
    }
  }
}

### Project

module "project" {
  source          = "../../../modules/project"
  name            = var.project_id
  project_create  = var.project_create == null ? false : true
  billing_account = try(var.project_create.billing_account_id, null)
  parent          = try(var.project_create.parent, null)
  service_config = {
    disable_dependent_services = false
    disable_on_destroy         = false
  }
  services = [
    "compute.googleapis.com",
    "dns.googleapis.com",
    "logging.googleapis.com",
    "trafficdirector.googleapis.com"
  ]
}

### Network

module "producer_vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.project.project_id
  name       = "${var.prefix}-producer"
  subnets = [
    {
      ip_cidr_range      = local.vpcs["producer"].proxies
      name               = "${var.prefix}-producer-proxies"
      region             = var.region
      secondary_ip_range = {}
    },
    {
      ip_cidr_range      = local.vpcs["producer"].service
      name               = "${var.prefix}-producer-service"
      region             = var.region
      secondary_ip_range = {}
    },
  ]
}

module "producer_firewall" {
  source             = "../../../modules/net-vpc-firewall"
  project_id         = module.project.project_id
  network            = module.producer_vpc.name
  data_folder        = "config/firewall-producer"
  cidr_template_file = "config/cidr_template.yaml"
}

module "producer_nat" {
  source         = "../../../modules/net-cloudnat"
  project_id     = module.project.project_id
  region         = var.region
  name           = "${var.prefix}-producer-nat"
  router_network = module.producer_vpc.name
}

module "consumer_vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.project.project_id
  name       = "${var.prefix}-consumer"
  routes = {
    for k, v in local.services : k => {
      dest_range    = "${v.frontend.address}/32"
      priority      = 1000
      next_hop_type = "ilb"
      next_hop      = module.envoy_ilb_address.internal_addresses["envoy-ilb"].address
      tags          = []
    }
  }
  subnets = [
    {
      ip_cidr_range      = local.vpcs["consumer"].proxies
      name               = "${var.prefix}-consumer-proxies"
      region             = var.region
      secondary_ip_range = {}
    },
    {
      ip_cidr_range      = local.vpcs["consumer"].client
      name               = "${var.prefix}-consumer-client"
      region             = var.region
      secondary_ip_range = {}
    },
  ]
}

module "consumer_firewall" {
  source             = "../../../modules/net-vpc-firewall"
  project_id         = module.project.project_id
  network            = module.consumer_vpc.name
  data_folder        = "config/firewall-consumer"
  cidr_template_file = "config/cidr_template.yaml"
}

module "consumer_nat" {
  source         = "../../../modules/net-cloudnat"
  project_id     = module.project.project_id
  region         = var.region
  name           = "${var.prefix}-consumer-nat"
  router_network = module.consumer_vpc.name
}

### VMs

module "client_vm" {
  source     = "../../../modules/compute-vm"
  project_id = module.project.project_id
  zone       = local.zones["b"]
  name       = "${var.prefix}-client-vm"
  network_interfaces = [{
    network    = module.consumer_vpc.self_link,
    subnetwork = module.consumer_vpc.subnet_self_links["${var.region}/${var.prefix}-consumer-client"],
    nat        = false,
    addresses  = null
  }]
  tags = ["ssh"]

  metadata = {
  }

  boot_disk = {
    image = "projects/debian-cloud/global/images/family/debian-11"
    type  = "pd-ssd"
    size  = 10
  }

  service_account_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
}

module "cos_nginx_tls" {
  source = "../../../modules/cloud-config-container/nginx-tls"
}

module "server_vm" {
  source     = "../../../modules/compute-vm"
  project_id = module.project.project_id
  zone       = local.zones["b"]
  name       = "${var.prefix}-server-vm"
  network_interfaces = [{
    network    = module.producer_vpc.self_link,
    subnetwork = module.producer_vpc.subnet_self_links["${var.region}/${var.prefix}-producer-service"],
    nat        = false,
    addresses = {
      external = null
      internal = local.services["svc-1"].backend.address
    }
  }]
  tags = ["ssh"]

  metadata = {
    user-data = module.cos_nginx_tls.cloud_config
  }

  boot_disk = {
    image = "projects/cos-cloud/global/images/family/cos-stable"
    type  = "pd-ssd"
    size  = 10
  }
}

module "cos_envoy_td" {
  source = "../../../modules/cloud-config-container/envoy-traffic-director"
}

module "envoy_template" {
  source          = "../../../modules/compute-vm"
  project_id      = module.project.project_id
  zone            = local.zones["b"]
  can_ip_forward  = true
  create_template = true
  name            = "${var.prefix}-proxy"
  network_interfaces = [{
    network    = module.producer_vpc.self_link,
    subnetwork = module.producer_vpc.subnet_self_links["${var.region}/${var.prefix}-producer-proxies"],
    nat        = false,
    addresses  = null
    },
    {
      network    = module.consumer_vpc.self_link,
      subnetwork = module.consumer_vpc.subnet_self_links["${var.region}/${var.prefix}-consumer-proxies"],
      nat        = false,
      addresses  = null
  }]
  tags = ["ssh"]

  metadata = {
    user-data = module.cos_envoy_td.cloud_config
  }

  boot_disk = {
    image = "projects/cos-cloud/global/images/family/cos-stable"
    type  = "pd-ssd"
    size  = 10
  }

  service_account_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
}

module "envoy_mig" {
  source      = "../../../modules/compute-mig"
  project_id  = module.project.project_id
  location    = var.region
  regional    = true
  name        = "${var.prefix}-proxy"
  target_size = 3
  default_version = {
    instance_template = module.envoy_template.template.self_link
    name              = "${var.prefix}-proxy"
  }

  auto_healing_policies = {
    health_check      = module.envoy_mig.health_check.self_link
    initial_delay_sec = 45
  }

  health_check_config = {
    type = "http"
    check = {
      request_path = "/ready"
      port         = 15000
    }
    config  = {}
    logging = true
  }

  depends_on = [
    module.envoy_ilb_address.internal_addresses
  ]
}

module "envoy_ilb_address" {
  source     = "../../../modules/net-address"
  project_id = var.project_id
  internal_addresses = {
    envoy-ilb = {
      address    = local.envoy_ilb_consumer_address
      region     = var.region
      subnetwork = module.consumer_vpc.subnet_self_links["${var.region}/${var.prefix}-consumer-proxies"]
    }
  }
}


module "envoy_ilb" {
  source        = "../../../modules/net-ilb"
  project_id    = var.project_id
  region        = var.region
  name          = "${var.prefix}-ilb"
  global_access = true
  address       = module.envoy_ilb_address.internal_addresses["envoy-ilb"].address
  #service_label = "ilb-test"
  network    = module.consumer_vpc.self_link
  subnetwork = module.consumer_vpc.subnet_self_links["${var.region}/${var.prefix}-consumer-proxies"]
  #ports      = [80]
  backends = [
    {
      failover       = false
      group          = module.envoy_mig.group_manager.instance_group
      balancing_mode = "CONNECTION"
    }
  ]
  health_check_config = {
    type = "http"
    check = {
      request_path = "/ready"
      port         = 15000
    }
    config  = {}
    logging = true
  }
}

### Traffic Director (this programs the Envoys to route traffic for the service)

#TODO: move to networkservices.googleapis.com once TF supports it

resource "google_compute_network_endpoint_group" "tcp_negs" {
  for_each = local.services

  name                  = "${var.prefix}-${each.key}-neg"
  network_endpoint_type = "NON_GCP_PRIVATE_IP_PORT"
  network               = module.producer_vpc.self_link
  zone                  = local.zones["b"]
  project               = module.project.project_id
}

resource "google_compute_network_endpoint" "tcp_neg_eps" {
  for_each = local.services

  network_endpoint_group = google_compute_network_endpoint_group.tcp_negs[each.key].name
  ip_address             = local.services[each.key].backend.address
  port                   = local.services[each.key].backend.port
  zone                   = local.zones["b"]
  project                = module.project.project_id
}

resource "google_compute_health_check" "tcp_health_checks" {
  for_each = local.services

  name = "${var.prefix}-${each.key}-hc"
  tcp_health_check {
    port = local.services[each.key].backend.port
  }
  project = module.project.project_id
}

resource "google_compute_backend_service" "tcp_services" {
  for_each = local.services

  protocol              = "TCP"
  name                  = "${var.prefix}-${each.key}-svc"
  load_balancing_scheme = "INTERNAL_SELF_MANAGED"
  health_checks         = [google_compute_health_check.tcp_health_checks[each.key].id]
  project               = module.project.project_id
  backend {
    group           = google_compute_network_endpoint_group.tcp_negs[each.key].id
    balancing_mode  = "CONNECTION"
    max_connections = 100
  }
}

resource "google_compute_target_tcp_proxy" "target_proxies" {
  for_each = local.services

  name            = "${var.prefix}-${each.key}-proxy"
  backend_service = google_compute_backend_service.tcp_services[each.key].id
  project         = module.project.project_id
}

resource "google_compute_global_forwarding_rule" "fwd_rule" {
  for_each = local.services

  name                  = "${var.prefix}-${each.key}-fwd-rule"
  target                = google_compute_target_tcp_proxy.target_proxies[each.key].id
  ip_address            = local.services[each.key].frontend.address
  port_range            = local.services[each.key].frontend.port
  network               = module.producer_vpc.self_link
  load_balancing_scheme = "INTERNAL_SELF_MANAGED"
  project               = module.project.project_id
}