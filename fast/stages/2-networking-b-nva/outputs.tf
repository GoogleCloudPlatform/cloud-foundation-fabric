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
  host_project_ids = {
    dev-spoke-0  = module.dev-spoke-project.project_id
    prod-landing = module.landing-project.project_id
    prod-spoke-0 = module.prod-spoke-project.project_id
  }
  host_project_numbers = {
    dev-spoke-0  = module.dev-spoke-project.number
    prod-landing = module.landing-project.number
    prod-spoke-0 = module.prod-spoke-project.number
  }
  subnet_self_links = merge({
    prod-dmz     = module.dmz-vpc.subnet_self_links
    prod-landing = module.landing-vpc.subnet_self_links
    dev-spoke-0  = module.dev-spoke-vpc.subnet_self_links
    prod-spoke-0 = module.prod-spoke-vpc.subnet_self_links
    },
    (var.network_mode == "regional_vpc") ? {
      regional-vpc-primary-0   = module.regional-primary-vpc[0].subnet_self_links
      regional-vpc-secondary-0 = module.regional-secondary-vpc[0].subnet_self_links
    } : {}
  )
  subnet_proxy_only_self_links = {
    prod-dmz = {
      for k, v in module.dmz-vpc.subnets_proxy_only : k => v.id
    }
    prod-landing = {
      for k, v in module.landing-vpc.subnets_proxy_only : k => v.id
    }
    dev-spoke-0 = {
      for k, v in module.dev-spoke-vpc.subnets_proxy_only : k => v.id
    }
    prod-spoke-0 = {
      for k, v in module.prod-spoke-vpc.subnets_proxy_only : k => v.id
    }
  }
  subnet_psc_self_links = {
    prod-dmz = {
      for k, v in module.dmz-vpc.subnets_psc : k => v.id
    }
    prod-landing = {
      for k, v in module.landing-vpc.subnets_psc : k => v.id
    }
    dev-spoke-0 = {
      for k, v in module.dev-spoke-vpc.subnets_psc : k => v.id
    }
    prod-spoke-0 = {
      for k, v in module.prod-spoke-vpc.subnets_psc : k => v.id
    }
  }
  tfvars = {
    host_project_ids             = local.host_project_ids
    host_project_numbers         = local.host_project_numbers
    subnet_self_links            = local.subnet_self_links
    subnet_proxy_only_self_links = local.subnet_proxy_only_self_links
    subnet_psc_self_links        = local.subnet_psc_self_links
    vpc_self_links               = local.vpc_self_links
  }
  vpc_self_links = merge(
    {
      prod-landing = module.landing-vpc.self_link
      prod-dmz     = module.dmz-vpc.self_link
      dev-spoke-0  = module.dev-spoke-vpc.self_link
      prod-spoke-0 = module.prod-spoke-vpc.self_link
    },
    (var.network_mode == "regional_vpc") ? {
      regional-vpc-primary-0   = module.regional-primary-vpc[0].self_link
      regional-vpc-secondary-0 = module.regional-secondary-vpc[0].self_link
    } : {}
  )
}

# generate tfvars file for subsequent stages

resource "local_file" "tfvars" {
  for_each        = var.outputs_location == null ? {} : { 1 = 1 }
  file_permission = "0644"
  filename        = "${try(pathexpand(var.outputs_location), "")}/tfvars/2-networking.auto.tfvars.json"
  content         = jsonencode(local.tfvars)
}

resource "google_storage_bucket_object" "tfvars" {
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

output "ping_commands" {
  description = "Ping commands for test instances to be run to check VPC reachability."
  value       = var.create_test_instances ? join("\n", [for instance, _ in local.test-vms : "ping -c 1 ${module.test-vms[instance].internal_ip} # ${instance}"]) : ""
}

output "shared_vpc_self_links" {
  description = "Shared VPC host projects."
  value       = local.vpc_self_links
}

output "tfvars" {
  description = "Terraform variables file for the following stages."
  sensitive   = true
  value       = local.tfvars
}

output "vpn_gateway_endpoints" {
  description = "External IP Addresses for the GCP VPN gateways."
  value = {
    onprem-primary = var.vpn_onprem_primary_config == null ? {} : {
      for v in module.landing-to-onprem-primary-vpn[0].gateway.vpn_interfaces :
      v.id => v.ip_address
    }
    onprem-secondary = var.vpn_onprem_secondary_config == null ? {} : {
      for v in module.landing-to-onprem-secondary-vpn[0].gateway.vpn_interfaces :
      v.id => v.ip_address
    }
  }
}
