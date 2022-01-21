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
# optionally generate providers and tfvars files for subsequent stages

locals {
  tfvars = {
    "03-project-factory-dev" = jsonencode({
      environment_dns_zone = module.dev-dns-private-zone.domain
      shared_vpc_self_link = module.dev-spoke-vpc.self_link
      vpc_host_project     = module.dev-spoke-project.project_id
    })
    "03-project-factory-prod" = jsonencode({
      environment_dns_zone = module.prod-dns-private-zone.domain
      shared_vpc_self_link = module.prod-spoke-vpc.self_link
      vpc_host_project     = module.prod-spoke-project.project_id
    })
  }
}

resource "local_file" "tfvars" {
  for_each = var.outputs_location == null ? {} : local.tfvars
  filename = "${var.outputs_location}/${each.key}/terraform-networking.auto.tfvars.json"
  content  = each.value
}

# outputs

output "cloud_dns_inbound_policy" {
  description = "IP Addresses for Cloud DNS inbound policy."
  value       = [for s in module.landing-vpc.subnets : cidrhost(s.ip_cidr_range, 2)]
}

output "project_ids" {
  description = "Network project ids."
  value = {
    dev     = module.dev-spoke-project.project_id
    landing = module.landing-project.project_id
    prod    = module.prod-spoke-project.project_id
  }
}

output "project_numbers" {
  description = "Network project numbers."
  value = {
    dev     = "projects/${module.dev-spoke-project.number}"
    landing = "projects/${module.landing-project.number}"
    prod    = "projects/${module.prod-spoke-project.number}"
  }
}

output "shared_vpc_host_projects" {
  description = "Shared VPC host projects."
  value = {
    landing = module.landing-project.project_id
    dev     = module.dev-spoke-project.project_id
    prod    = module.prod-spoke-project.project_id
  }
}


output "shared_vpc_self_links" {
  description = "Shared VPC host projects."
  value = {
    landing = module.landing-vpc.self_link
    dev     = module.dev-spoke-vpc.self_link
    prod    = module.prod-spoke-vpc.self_link
  }
}


output "vpn_gateway_endpoints" {
  description = "External IP Addresses for the GCP VPN gateways."
  value = {
    onprem-ew1 = { for v in module.landing-to-onprem-ew1-vpn.gateway.vpn_interfaces : v.id => v.ip_address }
  }
}

output "tfvars" {
  description = "Network-related variables used in other stages."
  sensitive   = true
  value       = local.tfvars
}
