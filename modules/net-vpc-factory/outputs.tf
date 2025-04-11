/**
 * Copyright 2025 Google LLC
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

output "host_project_ids" {
  description = "Network project ids."
  value       = { for k, v in module.projects : k => v.project_id }
}

output "host_project_numbers" {
  description = "Network project numbers."
  value       = { for k, v in module.projects : k => v.number }
}

output "subnet_ids" {
  description = "IDs of subnets created within each VPC."
  value       = { for k, v in module.vpc : k => v.subnet_ids }
}

output "subnet_proxy_only_self_links" {
  description = "IDs of proxy-only subnets created within each VPC."
  value = {
    for k, v in module.vpc : k =>
    {
      for subnet_key, subnet_value in v.subnets_proxy_only : subnet_key => subnet_value.id
    }
  }
}

output "subnet_psc_self_links" {
  description = "IDs of PSC subnets created within each VPC."
  value = {
    for k, v in module.vpc : k =>
    {
      for subnet_key, subnet_value in v.subnets_psc : subnet_key => subnet_value.id
    }
  }
}

output "vpc_self_links" {
  description = "Self-links for the VPCs created on each project."
  value       = { for k, v in module.vpc : k => v.self_link }
}

output "vpn_gateway_endpoints" {
  description = "External IP Addresses for the GCP VPN gateways."
  value = { for k, v in google_compute_ha_vpn_gateway.default : k =>
    {
      for interface_key, interface_value in v.vpn_interfaces : interface_key => interface_value.ip_address
    }
  }
}
