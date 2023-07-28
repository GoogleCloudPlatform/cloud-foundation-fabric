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
    core = module.net-project.project_id
  }
  host_project_numbers = {
    core = module.net-project.number
  }
  tfvars = {
    host_project_ids     = local.host_project_ids
    host_project_numbers = local.host_project_numbers
    vpc_self_links       = local.vpc_self_links
  }
  vpc_self_links = {
    dmz               = module.dmz-vpc.id
    external          = module.external-vpc.id
    management        = module.mgmt-vpc.id
    shared            = module.shared-vpc.id
    transit-primary   = module.transit-primary-vpc.id
    transit-secondary = module.transit-secondary-vpc.id
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

output "tfvars" {
  description = "Terraform variables file for the following stages."
  sensitive   = true
  value       = local.tfvars
}

output "vlan_attachments_pairing_keys" {
  description = "Pairing keys generated for VLAN Attachments"
  value = {
    primary-a   = module.primary-a-vlan-attachment.pairing_key
    primary-b   = module.primary-b-vlan-attachment.pairing_key
    secondary-a = module.secondary-a-vlan-attachment.pairing_key
    secondary-b = module.secondary-b-vlan-attachment.pairing_key
  }
}
