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
  host_project_ids = {
    dev-spoke-0  = module.dev-project.project_id
    prod-landing = module.hub-project.project_id
    prod-spoke-0 = module.prod-project.project_id
  }
  host_project_numbers = {
    dev          = module.dev-project.number
    prod-landing = module.hub-project.number
    prod         = module.prod-project.number
  }
  subnet_self_links = {
    dev-spoke-0    = module.dev-vpc.subnet_ids
    prod-spoke-0   = module.prod-vpc.subnet_ids
    hub-management = module.hub-management-vpc.subnet_ids
    hub-untrusted  = module.hub-untrusted-vpc.subnet_ids
    hub-dmz        = module.hub-dmz-vpc.subnet_ids
    hub-inside     = module.hub-inside-vpc.subnet_ids
    hub-trusted    = module.hub-trusted-prod-vpc.subnet_ids
  }
  tfvars = {
    host_project_ids     = local.host_project_ids
    host_project_numbers = local.host_project_numbers
    subnet_self_links    = local.subnet_self_links
    vpc_self_links       = local.vpc_self_links
  }
  vpc_self_links = {
    dev-spoke-0    = module.dev-vpc.id
    hub-management = module.hub-management-vpc.id
    hub-untrusted  = module.hub-untrusted-vpc.id
    hub-dmz        = module.hub-dmz-vpc.id
    hub-inside     = module.hub-inside-vpc.id
    hub-trusted    = module.hub-trusted-prod-vpc.id
    prod-spoke-0   = module.prod-vpc.id
  }
}

# generate tfvars file for subsequent stages

resource "local_file" "tfvars" {
  for_each        = var.outputs_location == null ? {} : { 1 = 1 }
  file_permission = "0644"
  filename        = "${try(pathexpand(var.outputs_location), "")}/tfvars/2-networking.auto.tfvars.json"
  content         = jsonencode(local.tfvars)
}

resource "google_storage_bucket_object" "tfvars" {
  count   = try(var.automation.outputs_bucket, null) == null ? 0 : 1
  bucket  = var.automation.outputs_bucket
  name    = "tfvars/2-networking.auto.tfvars.json"
  content = jsonencode(local.tfvars)
}

# outputs

output "host_project_ids" {
  description = "Network project ids."
  value       = local.host_project_ids
}

output "host_project_numbers" {
  description = "Network project numbers."
  value       = local.host_project_numbers
}

output "shared_vpc_self_links" {
  description = "Shared VPC host projects."
  value       = local.vpc_self_links
}

output "test-instances" {
  value = {
    # nva-external = {
    #   ilb = module.hub-nva-ext-ilb-dmz.forwarding_rule_address
    #   vm  = try(module.hub-nva-external["a"].internal_ip, null)
    # }
    # nva-external = {
    #   ilb = {
    #     for k, v in module.hub-nva-internal-ilb :
    #     k => v.forwarding_rule_address
    #   }
    #   vm = try(module.hub-nva-internal["a"].internal_ip, null)
    # }
    test-dev-0       = module.test-vm-dev-0.internal_ip
    test-dmz-0       = module.test-vm-dmz-0.internal_ip
    test-inside-0    = module.test-vm-inside-0.internal_ip
    test-prod-0      = module.test-vm-prod-0.internal_ip
    test-untrusted-0 = module.test-vm-untrusted-0.internal_ip
  }
}

output "tfvars" {
  description = "Terraform variables file for the following stages."
  sensitive   = true
  value       = local.tfvars
}

output "vpn_gateway_endpoints" {
  description = "External IP Addresses for the GCP VPN gateways."
  value = var.vpn_config == null ? null : {
    onprem-primary = {
      for v in module.landing-to-onprem-primary-vpn[0].gateway.vpn_interfaces :
      v.id => v.ip_address
    }
  }
}
