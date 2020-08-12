/**
 * Copyright 2020 Google LLC
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

module "gw-hub" {
  source        = "../../modules/compute-vm"
  project_id    = var.project_id
  region        = var.region
  name          = "${local.prefix}gw-hub"
  instance_type = var.gateway_config.instance_type
  boot_disk = {
    image = var.gateway_config.image, type = "pd-ssd", size = 10
  }
  network_interfaces = [
    {
      network    = module.vpc-hub.self_link
      subnetwork = local.subnets.hub,
      nat        = false,
      addresses  = null
    },
    {
      network    = module.vpc-landing.self_link
      subnetwork = local.subnets.landing,
      nat        = false,
      addresses  = { internal = local.addresses_hub_gw, external = null }
    }
  ]
  tags           = ["ssh"]
  can_ip_forward = true
  metadata_list = [
    for i in range(var.gateway_config.instance_count) : {
      user-data = templatefile("assets/gw-hub.yaml", {
        local         = local.addresses_hub_gw[i]
        remote        = local.addresses.landing-gw
        remote_range  = var.ip_ranges.onprem
        tunnel_local  = cidrhost(local.subnets_tunnel[i], 2)
        tunnel_remote = cidrhost(local.subnets_tunnel[i], 1)
      })
    }
  ]
  service_account = try(
    module.service-accounts.emails["${local.prefix}gce-vm"], null
  )
  service_account_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  instance_count         = 2
}

module "gw-onprem" {
  source        = "../../modules/compute-vm"
  project_id    = var.project_id
  region        = var.region
  name          = "${local.prefix}gw-onprem"
  instance_type = var.gateway_config.instance_type
  boot_disk = {
    image = var.gateway_config.image, type = "pd-ssd", size = 10
  }
  network_interfaces = [
    {
      network    = module.vpc-onprem.self_link
      subnetwork = local.subnets.onprem,
      nat        = false,
      addresses  = { internal = [local.addresses.onprem-gw], external = null }
    },
    {
      network    = module.vpc-landing.self_link
      subnetwork = local.subnets.landing,
      nat        = false,
      addresses  = { internal = [local.addresses.landing-gw], external = null }
    },
  ]
  tags           = ["ssh"]
  can_ip_forward = true
  metadata = {
    user-data = templatefile("assets/gw-onprem.yaml", {
      local          = local.addresses.landing-gw
      remotes        = local.addresses_hub_gw
      remote_range   = var.ip_ranges.hub
      remotes_num    = var.gateway_config.instance_count
      tunnel_locals  = [for s in local.subnets_tunnel : cidrhost(s, 1)]
      tunnel_remotes = [for s in local.subnets_tunnel : cidrhost(s, 2)]
    })
  }
  service_account = try(
    module.service-accounts.emails["${local.prefix}gce-vm"], null
  )
  service_account_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  instance_count         = 1
}
