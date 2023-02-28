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
  cloud_config = templatefile(local.template, merge({
    files                = local.files
    enable_health_checks = var.enable_health_checks
    network_interfaces   = local.network_interfaces
    optional_run_cmds    = local.optional_run_cmds
  }))

  frr_config = (
    try(var.bgp_config.frr_config != null, false) ? var.bgp_config.frr_config : "${path.module}/files/frr/frr.conf"
  )
  daemons = (
    try(var.bgp_config.daemons != null, false) ? var.bgp_config.daemons : "${path.module}/files/frr/daemons"
  )
  files = merge(
    {
      "/var/run/nva/ipprefix_by_netmask.sh" = {
        content     = file("${path.module}/files/ipprefix_by_netmask.sh")
        owner       = "root"
        permissions = "0744"
      }
      "/var/run/nva/policy_based_routing.sh" = {
        content     = file("${path.module}/files/policy_based_routing.sh")
        owner       = "root"
        permissions = "0744"
      }
      }, {
      for path, attrs in var.files : path => {
        content     = attrs.content,
        owner       = attrs.owner,
        permissions = attrs.permissions
      }
    },
    try(var.bgp_config.enable, false) ? {
      "/etc/frr/daemons" = {
        content     = file(local.daemons)
        owner       = "root"
        permissions = "0744"
      }
      "/etc/frr/frr.conf" = {
        content     = file(local.frr_config)
        owner       = "root"
        permissions = "0744"
      }
      "/etc/systemd/system/frr.service" = {
        content     = file("${path.module}/files/frr/frr.service")
        owner       = "root"
        permissions = "0644"
      }
      "/var/lib/docker/daemon.json" = {
        content     = <<EOF
        {
          "live-restore": true,
          "storage-driver": "overlay2",
          "log-opts": {
            "max-size": "1024m"
          }
        }
        EOF
        owner       = "root"
        permissions = "0644"
      }
    } : {}
  )

  network_interfaces = [
    for index, interface in var.network_interfaces : {
      name                = "eth${index}"
      number              = index
      routes              = interface.routes
      enable_masquerading = interface.enable_masquerading != null ? interface.enable_masquerading : false
      non_masq_cidrs      = interface.non_masq_cidrs != null ? interface.non_masq_cidrs : []
    }
  ]

  optional_run_cmds = try(var.bgp_config.enable, false) ? concat(
    ["systemctl start frr"], var.optional_run_cmds
  ) : var.optional_run_cmds

  template = (
    var.cloud_config == null
    ? "${path.module}/cloud-config.yaml"
    : var.cloud_config
  )
}
