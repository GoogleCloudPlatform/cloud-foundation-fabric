/**
 * Copyright 2024 Google LLC
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
  _f5_urls = {
    as3  = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.46.0/f5-appsvcs-3.46.0-5.noarch.rpm"
    cfe  = "https://github.com/F5Networks/f5-cloud-failover-extension/releases/download/v1.15.0/f5-cloud-failover-1.15.0-0.noarch.rpm"
    do   = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.39.0/f5-declarative-onboarding-1.39.0-4.noarch.rpm"
    fast = "https://github.com/F5Networks/f5-appsvcs-templates/releases/download/v1.25.0/f5-appsvcs-templates-1.25.0-1.noarch.rpm"
    init = "https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v1.6.2/dist/f5-bigip-runtime-init-1.6.2-1.gz.run"
    ts   = "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.33.0/f5-telemetry-1.33.0-1.noarch.rpm"
  }
  _f5_urls_split = {
    for k, v in local._f5_urls
    : k => split("/", v)
  }
  _f5_vers = {
    as3  = split("-", local._f5_urls_split.as3[length(local._f5_urls_split.as3) - 1])[2]
    cfe  = split("-", local._f5_urls_split.cfe[length(local._f5_urls_split.cfe) - 1])[3]
    do   = split("-", local._f5_urls_split.do[length(local._f5_urls_split.do) - 1])[3]
    fast = format("v%s", split("-", local._f5_urls_split.fast[length(local._f5_urls_split.fast) - 1])[3])
    ts   = format("v%s", split("-", local._f5_urls_split.ts[length(local._f5_urls_split.ts) - 1])[2])
  }
  f5_config = merge(
    { NIC_COUNT = true },
    { for k, v in local._f5_urls : upper("${k}_url") => v },
    { for k, v in local._f5_vers : upper("${k}_ver") => v },
  )
}

module "vm-addresses-dp" {
  source     = "../../../../modules/net-address"
  project_id = var.project_id
  internal_addresses = {
    for k, v in var.instance_dedicated_configs : k => {
      address    = try(v.network_config.dataplane_address, null)
      name       = "${var.prefix}-${k}-dp"
      region     = var.region
      subnetwork = var.vpc_config.dataplane.subnetwork
    }
  }
}

module "vm-addresses-mgmt" {
  source     = "../../../../modules/net-address"
  project_id = var.project_id
  internal_addresses = {
    for k, v in var.instance_dedicated_configs
    : k => {
      address    = try(v.network_config.management_address, null)
      name       = "${var.prefix}-${k}-mgmt"
      region     = var.region
      subnetwork = var.vpc_config.management.subnetwork
    }
  }
}

module "bigip-vms" {
  for_each       = var.instance_dedicated_configs
  source         = "../../../../modules/compute-vm"
  project_id     = var.project_id
  zone           = "${var.region}-${each.key}"
  name           = "${var.prefix}-lb-${each.key}"
  instance_type  = var.instance_shared_config.instance_type
  can_ip_forward = true
  tags           = var.instance_shared_config.tags

  boot_disk = {
    initialize_params = var.instance_shared_config.boot_disk
  }

  group = {
    named_ports = {}
  }

  metadata = {
    startup-script = replace(templatefile("${path.module}/startup-script.tpl",
      merge(local.f5_config, {
        onboard_log                       = "/var/log/startup-script.log",
        libs_dir                          = "/config/cloud/gcp/node_modules",
        bigip_username                    = var.instance_shared_config.username,
        gcp_secret_manager_authentication = var.instance_shared_config.secret.is_gcp,
        bigip_password                    = var.instance_shared_config.secret.value,
        license_key                       = each.value.license_key,
        ssh_keypair                       = try(file(var.instance_shared_config.ssh_public_key), ""),
    })), "/\r/", "")
  }

  network_interfaces = [
    {
      network    = var.vpc_config.dataplane.network
      subnetwork = var.vpc_config.dataplane.subnetwork
      stack_type = (
        var.instance_shared_config.enable_ipv6
        ? "IPV4_IPV6"
        : "IPV4_ONLY"
      )
      addresses = {
        internal = module.vm-addresses-dp.internal_addresses["${var.prefix}-${each.key}-dp"].address
      }
      alias_ips = {
        (each.value.network_config.alias_ip_range_name) = each.value.network_config.alias_ip_range_address
      }
    },
    {
      network    = var.vpc_config.management.network
      subnetwork = var.vpc_config.management.subnetwork
      stack_type = (
        var.instance_shared_config.enable_ipv6
        ? "IPV4_IPV6"
        : "IPV4_ONLY"
      )
      addresses = {
        internal = module.vm-addresses-mgmt.internal_addresses["${var.prefix}-${each.key}-mgmt"].address
      }
    }
  ]

  service_account = {
    email = var.instance_shared_config.service_account
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/userinfo.email"
    ]
  }
}
