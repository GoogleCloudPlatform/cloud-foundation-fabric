/**
 * Copyright 2021 Google LLC
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
  squid_address = (
    var.mig
    ? module.squid-ilb.0.forwarding_rule_address
    : module.squid-vm.internal_ips.0
  )
}

###############################################################################
#                    Folder with network-related resources                    #
###############################################################################

module "folder-netops" {
  source = "../../modules/folder"
  parent = var.root_node
  name   = "netops"
}

###############################################################################
#                    Host project and shared VPC resources                    #
###############################################################################

module "project-host" {
  source          = "../../modules/project"
  billing_account = var.billing_account
  name            = "host"
  parent          = module.folder-netops.id
  prefix          = var.prefix
  services = [
    "compute.googleapis.com",
    "dns.googleapis.com",
    "logging.googleapis.com"
  ]
  shared_vpc_host_config = {
    enabled          = true
    service_projects = []
  }
}

module "vpc" {
  source     = "../../modules/net-vpc"
  project_id = module.project-host.project_id
  name       = "vpc"
  subnets = [
    {
      name               = "apps"
      ip_cidr_range      = var.cidrs.apps
      region             = var.region
      secondary_ip_range = null
    },
    {
      name               = "proxy"
      ip_cidr_range      = var.cidrs.proxy
      region             = var.region
      secondary_ip_range = null
    }
  ]
}

module "firewall" {
  source     = "../../modules/net-vpc-firewall"
  project_id = module.project-host.project_id
  network    = module.vpc.name
  custom_rules = {
    allow-ingress-squid = {
      description          = "Allow squid ingress traffic"
      direction            = "INGRESS"
      action               = "allow"
      sources              = []
      ranges               = [var.cidrs.apps, "35.191.0.0/16", "130.211.0.0/22"]
      targets              = [module.service-account-squid.email]
      use_service_accounts = true
      rules                = [{ protocol = "tcp", ports = [3128] }]
      extra_attributes     = {}
    }
  }
}

module "nat" {
  source                = "../../modules/net-cloudnat"
  project_id            = module.project-host.project_id
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

module "private-dns" {
  source          = "../../modules/dns"
  project_id      = module.project-host.project_id
  type            = "private"
  name            = "internal"
  domain          = "internal."
  client_networks = [module.vpc.self_link]
  recordsets = [
    { name = "squid", type = "A", ttl = 60, records = [local.squid_address] },
    { name = "proxy", type = "CNAME", ttl = 3600, records = ["squid.internal."] }
  ]
}

###############################################################################
#                               Squid resources                               #
###############################################################################

module "service-account-squid" {
  source     = "../../modules/iam-service-account"
  project_id = module.project-host.project_id
  name       = "svc-squid"
  iam_project_roles = {
    (module.project-host.project_id) = [
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
    ]
  }
}

module "cos-squid" {
  source  = "../../modules/cloud-config-container/squid"
  allow   = var.allowed_domains
  clients = [var.cidrs.apps]
}

module "squid-vm" {
  source        = "../../modules/compute-vm"
  project_id    = module.project-host.project_id
  region        = var.region
  name          = "squid-vm"
  instance_type = "e2-medium"
  network_interfaces = [{
    network    = module.vpc.self_link
    subnetwork = module.vpc.subnet_self_links["${var.region}/proxy"]
    nat        = false
    addresses  = null
    alias_ips  = null
  }]
  boot_disk = {
    image = "cos-cloud/cos-stable"
    type  = "pd-standard"
    size  = 10
  }
  service_account        = module.service-account-squid.email
  service_account_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  use_instance_template  = var.mig
  metadata = {
    user-data = module.cos-squid.cloud_config
  }
}

module "squid-mig" {
  count       = var.mig ? 1 : 0
  source      = "../../modules/compute-mig"
  project_id  = module.project-host.project_id
  location    = "${var.region}-b"
  name        = "squid-mig"
  target_size = 1
  autoscaler_config = {
    max_replicas                      = 10
    min_replicas                      = 1
    cooldown_period                   = 30
    cpu_utilization_target            = 0.65
    load_balancing_utilization_target = null
    metric                            = null
  }
  default_version = {
    instance_template = module.squid-vm.template.self_link
    name              = "default"
  }
  health_check_config = {
    type    = "tcp"
    check   = { port = 3128 }
    config  = {}
    logging = true
  }
  auto_healing_policies = {
    health_check      = module.squid-mig.0.health_check.self_link
    initial_delay_sec = 60
  }
}

module "squid-ilb" {
  count         = var.mig ? 1 : 0
  source        = "../../modules/net-ilb"
  project_id    = module.project-host.project_id
  region        = var.region
  name          = "squid-ilb"
  service_label = "squid-ilb"
  network       = module.vpc.self_link
  subnetwork    = module.vpc.subnet_self_links["${var.region}/proxy"]
  ports         = [3128]
  backends = [{
    failover       = false
    group          = module.squid-mig.0.group_manager.instance_group
    balancing_mode = "CONNECTION"
  }]
  health_check_config = {
    type    = "tcp"
    check   = { port = 3128 }
    config  = {}
    logging = true
  }
}

###############################################################################
#                               Service project                               #
###############################################################################

module "folder-apps" {
  source = "../../modules/folder"
  parent = var.root_node
  name   = "apps"
  policy_list = {
    # prevent VMs with public IPs in the apps folder
    "constraints/compute.vmExternalIpAccess" = {
      inherit_from_parent = false
      suggested_value     = null
      status              = false
      values              = []
    }
  }
}

module "project-app" {
  source          = "../../modules/project"
  billing_account = var.billing_account
  name            = "app1"
  parent          = module.folder-apps.id
  prefix          = var.prefix
  services        = ["compute.googleapis.com"]
  shared_vpc_service_config = {
    attach       = true
    host_project = module.project-host.project_id
  }
}

module "test-vm" {
  source        = "../../modules/compute-vm"
  project_id    = module.project-app.project_id
  region        = var.region
  name          = "test-vm"
  instance_type = "e2-micro"
  tags          = ["ssh"]
  network_interfaces = [{
    network    = module.vpc.self_link
    subnetwork = module.vpc.subnet_self_links["${var.region}/apps"]
    nat        = false
    addresses  = null
    alias_ips  = null
  }]
  boot_disk = {
    image = "debian-cloud/debian-10"
    type  = "pd-standard"
    size  = 10
  }
  service_account_create = true
}
