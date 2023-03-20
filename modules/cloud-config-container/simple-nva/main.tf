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
  _files = merge(
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
    try(var.frr_config != null, false) ? {
      "/etc/frr/daemons" = {
        content     = templatefile("${path.module}/files/frr/daemons", local._frr_daemons_enabled)
        owner       = "root"
        permissions = "0744"
      }
      "/etc/frr/frr.conf" = {
        # content can either be the path to the config file or the config string
        content     = try(file(var.frr_config.config_file), var.frr_config.config_file)
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

  _frr_daemons = [
    "zebra",
    "bgpd",
    "ospfd",
    "ospf6d",
    "ripd",
    "ripngd",
    "isisd",
    "pimd",
    "ldpd",
    "nhrpd",
    "eigrpd",
    "babeld",
    "sharpd",
    "staticd",
    "pbrd",
    "bfdd",
    "fabricd"
  ]

  _frr_daemons_enabled = try(
    {
      for daemon in local._frr_daemons :
      "${daemon}_enabled" => contains(var.frr_config.daemons_enabled, daemon) ? "yes" : "no"
  }, {})

  _network_interfaces = [
    for index, interface in var.network_interfaces : {
      name                = "eth${index}"
      number              = index
      routes              = interface.routes
      enable_masquerading = interface.enable_masquerading != null ? interface.enable_masquerading : false
      non_masq_cidrs      = interface.non_masq_cidrs != null ? interface.non_masq_cidrs : []
    }
  ]

  _optional_run_cmds = (
    try(var.frr_config != null, false)
    ? concat(["systemctl start frr"], var.optional_run_cmds)
    : var.optional_run_cmds
  )

  _template = (
    var.cloud_config == null
    ? "${path.module}/cloud-config.yaml"
    : var.cloud_config
  )

  cloud_config = templatefile(local._template, {
    enable_health_checks = var.enable_health_checks
    files                = local._files
    network_interfaces   = local._network_interfaces
    optional_run_cmds    = local._optional_run_cmds
  })
}
