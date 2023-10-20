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

locals {
  # F5 configs
  as3_url  = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.46.0/f5-appsvcs-3.46.0-5.noarch.rpm"
  as3_ver  = format("v%s", split("-", split("/", local.as3_url)[length(split("/", local.as3_url)) - 1])[2])
  cfe_ver  = format("v%s", split("-", split("/", local.cfe_url)[length(split("/", local.cfe_url)) - 1])[3])
  cfe_url  = "https://github.com/F5Networks/f5-cloud-failover-extension/releases/download/v1.15.0/f5-cloud-failover-1.15.0-0.noarch.rpm"
  do_url   = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.39.0/f5-declarative-onboarding-1.39.0-4.noarch.rpm"
  do_ver   = format("v%s", split("-", split("/", local.do_url)[length(split("/", local.do_url)) - 1])[3])
  fast_url = "https://github.com/F5Networks/f5-appsvcs-templates/releases/download/v1.25.0/f5-appsvcs-templates-1.25.0-1.noarch.rpm"
  fast_ver = format("v%s", split("-", split("/", local.fast_url)[length(split("/", local.fast_url)) - 1])[3])
  init_url = "https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v1.6.2/dist/f5-bigip-runtime-init-1.6.2-1.gz.run"
  ts_ver   = format("v%s", split("-", split("/", local.ts_url)[length(split("/", local.ts_url)) - 1])[2])
  ts_url   = "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.33.0/f5-telemetry-1.33.0-1.noarch.rpm"
}

module "vm-addresses-dp" {
  source     = "../../../../modules/net-address"
  project_id = var.project_id
  internal_addresses = {
    for k, v in var.f5_vms_dedicated_config
    : k => {
      address    = try(v.network_config.dataplane_address, null)
      name       = "${var.prefix}-f5-ip-dp-${k}"
      region     = var.region
      subnetwork = var.vpc_config.dataplane.subnetwork
    }
  }
}

module "vm-addresses-mgmt" {
  source     = "../../../../modules/net-address"
  project_id = var.project_id
  internal_addresses = {
    for k, v in var.f5_vms_dedicated_config
    : k => {
      address    = try(v.network_config.management_address, null)
      name       = "${var.prefix}-f5-ip-mgmt-${k}"
      region     = var.region
      subnetwork = var.vpc_config.management.subnetwork
    }
  }
}

module "bigip-vms" {
  for_each       = var.f5_vms_dedicated_config
  source         = "../../../../modules/compute-vm"
  project_id     = var.project_id
  zone           = "${var.region}-${each.key}"
  name           = "${var.prefix}-f5-lb-${each.key}"
  instance_type  = var.f5_vms_shared_config.instance_type
  can_ip_forward = true
  tags           = var.f5_vms_shared_config.tags

  boot_disk = {
    initialize_params = {
      image = var.f5_vms_shared_config.image
      size  = var.f5_vms_shared_config.disk_size
      type  = "pd-ssd"
    }
  }

  group = {
    named_ports = {}
  }

  metadata = {
    startup-script = replace(templatefile("${path.module}/startup-script.tpl", {
      onboard_log                       = "/var/log/startup-script.log",
      libs_dir                          = "/config/cloud/gcp/node_modules",
      bigip_username                    = var.f5_vms_shared_config.username,
      gcp_secret_manager_authentication = var.f5_vms_shared_config.use_gcp_secret ? true : false,
      bigip_password                    = var.f5_vms_shared_config.secret,
      license_key                       = each.value.license_key,
      ssh_keypair                       = try(file(var.f5_vms_shared_config.ssh_public_key), ""),
      INIT_URL                          = local.init_url
      DO_URL                            = local.do_url
      DO_VER                            = local.do_ver
      AS3_URL                           = local.as3_url
      AS3_VER                           = local.as3_ver
      TS_VER                            = local.ts_ver
      TS_URL                            = local.ts_url
      CFE_VER                           = local.cfe_ver
      CFE_URL                           = local.cfe_url
      FAST_URL                          = local.fast_url
      FAST_VER                          = local.fast_ver
      NIC_COUNT                         = true
    }), "/\r/", "")
  }

  network_interfaces = [
    {
      network    = var.vpc_config.dataplane.network
      subnetwork = var.vpc_config.dataplane.subnetwork
      stack_type = (
        var.f5_vms_shared_config.enable_ipv6
        ? "IPV4_IPV6"
        : "IPV4_ONLY"
      )
      addresses = {
        internal = module.vm-addresses-dp.internal_addresses["${var.prefix}-f5-ip-dp-${each.key}"].address
      }
      alias_ips = {
        "${each.value.network_config.alias_ip_range_name}" = each.value.network_config.alias_ip_range_address
      }
    },
    {
      network    = var.vpc_config.management.network
      subnetwork = var.vpc_config.management.subnetwork
      stack_type = (
        var.f5_vms_shared_config.enable_ipv6
        ? "IPV4_IPV6"
        : "IPV4_ONLY"
      )
      addresses = {
        internal = module.vm-addresses-mgmt.internal_addresses["${var.prefix}-f5-ip-mgmt-${each.key}"].address
      }
    }
  ]

  service_account = {
    email = var.f5_vms_shared_config.service_account
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/userinfo.email"
    ]
  }
}
