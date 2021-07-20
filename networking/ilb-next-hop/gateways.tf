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

module "gw" {
  source        = "../../modules/compute-vm"
  project_id    = module.project.project_id
  region        = var.region
  zones         = local.zones
  name          = "${local.prefix}gw"
  instance_type = "f1-micro"

  boot_disk = {
    image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2004-lts",
    type  = "pd-ssd",
    size  = 10
  }

  network_interfaces = [
    {
      network    = module.vpc-left.self_link
      subnetwork = values(module.vpc-left.subnet_self_links)[0],
      nat        = false,
      addresses  = null,
      alias_ips  = null
    },
    {
      network    = module.vpc-right.self_link
      subnetwork = values(module.vpc-right.subnet_self_links)[0],
      nat        = false,
      addresses  = null,
      alias_ips  = null
    }
  ]
  tags           = ["ssh"]
  can_ip_forward = true
  metadata = {
    user-data = templatefile("${path.module}/assets/gw.yaml", {
      gw_right      = cidrhost(var.ip_ranges.right, 1)
      ip_cidr_right = var.ip_ranges.right
    })
  }
  service_account = try(
    module.service-accounts.emails["${local.prefix}gce-vm"], null
  )
  service_account_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  instance_count         = 2
  group                  = { named_ports = null }
}

module "ilb-left" {
  source     = "../../modules/net-ilb"
  project_id = module.project.project_id
  region     = var.region
  name       = "${local.prefix}ilb-left"
  network    = module.vpc-left.self_link
  subnetwork = values(module.vpc-left.subnet_self_links)[0]
  address    = local.addresses.ilb-left
  ports      = null
  backend_config = {
    session_affinity                = var.ilb_session_affinity
    timeout_sec                     = null
    connection_draining_timeout_sec = null
  }
  backends = [for zone, group in module.gw.groups : {
    failover       = false
    group          = group.self_link
    balancing_mode = "CONNECTION"
  }]
  health_check_config = {
    type = "tcp", check = { port = 22 }, config = {}, logging = true
  }
}

module "ilb-right" {
  source     = "../../modules/net-ilb"
  project_id = module.project.project_id
  region     = var.region
  name       = "${local.prefix}ilb-right"
  network    = module.vpc-right.self_link
  subnetwork = values(module.vpc-right.subnet_self_links)[0]
  address    = local.addresses.ilb-right
  ports      = null
  backend_config = {
    session_affinity                = var.ilb_session_affinity
    timeout_sec                     = null
    connection_draining_timeout_sec = null
  }
  backends = [for zone, group in module.gw.groups : {
    failover       = false
    group          = group.self_link
    balancing_mode = "CONNECTION"
  }]
  health_check_config = {
    type = "tcp", check = { port = 22 }, config = {}, logging = true
  }
}
