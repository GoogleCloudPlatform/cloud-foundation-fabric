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
  cloud_config = templatefile(local.template, merge(local.config_variables, {
    files                = local.files
    enable_health_checks = var.enable_health_checks
    network_interfaces   = local.network_interfaces
  }))
  frr_config = (
    var.frr_config == null ? "${path.module}/files/frr/frr.conf" : var.frr_config
  )
  daemons = (
    var.daemons == null ? "${path.module}/files/frr/deamons" : var.daemons
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
    },{
      for path, attrs in var.files : path => {
        content     = attrs.content,
        owner       = attrs.owner,
        permissions = attrs.permissions
      }
    },
    var.enable_bgp ? {
      "/etc/frr/daemons" = {
      content     = templatefile(local.daemons, local.config_variables)
      owner       = "frr"
      permissions = "0744"
      }
      "/etc/frr/frr.conf" = {
      content     = file(local.frr_config)
      owner       = "frr"
      permissions = "0744"
      }
    } : {}
  )
  network_interfaces = [
    for index, interface in var.network_interfaces : {
      name   = "eth${index}"
      number = index
      routes = interface.routes
    }
  ]
  template = (
    var.cloud_config == null
    ? "${path.module}/cloud-config.yaml"
    : var.cloud_config
  )
  config_variables = merge(var.config_variables, {
    enable_bgp = var.enable_bgp
  })
}
