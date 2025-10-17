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

locals {
  tfvars = {
    host_project_ids     = module.projects.project_ids
    host_project_numbers = module.projects.project_numbers
    subnet_self_links = {
      for vpc_key, vpc in module.vpcs : vpc_key => vpc.subnet_ids
    }
    subnet_proxy_only_self_links = {
      for vpc_key, vpc in module.vpcs : vpc_key => {
        for subnet_key, subnet in vpc.subnets_proxy_only : subnet_key => subnet.id
      }
    }
    subnet_psc_self_links = {
      for vpc_key, vpc in module.vpcs : vpc_key => {
        for subnet_key, subnet in vpc.subnets_psc : subnet_key => subnet.id
      }
    }
    vpc_self_links = {
      for vpc_key, vpc in module.vpcs : vpc_key => vpc.id
    }
  }
}

# generate tfvars file for subsequent stages

resource "local_file" "tfvars" {
  for_each        = var.outputs_location == null ? {} : { 1 = 1 }
  file_permission = "0644"
  filename        = "${try(pathexpand(var.outputs_location), "")}tfvars/2-networking.auto.tfvars.json"
  content         = jsonencode(local.tfvars)
}

resource "google_storage_bucket_object" "tfvars" {
  for_each = try(var.automation.outputs_bucket, null) == null ? {} : { 1 = 1 }
  bucket   = var.automation.outputs_bucket
  name     = "tfvars/2-networking.auto.tfvars.json"
  content  = jsonencode(local.tfvars)
}

resource "google_storage_bucket_object" "version" {
  for_each = try(var.automation.outputs_bucket, null) == null || !fileexists("fast_version.txt") ? {} : { 1 = 1 }
  bucket   = var.automation.outputs_bucket
  name     = "versions/2-networking-version.txt"
  source   = "fast_version.txt"
}

# outputs

output "host_project_ids" {
  description = "Project IDs."
  value       = local.tfvars.host_project_ids
}

output "host_project_numbers" {
  description = "Project numbers."
  value       = local.tfvars.host_project_numbers
}

output "subnet_self_links" {
  description = "Subnet self-links."
  value       = local.tfvars.subnet_self_links
}

output "subnet_proxy_only_self_links" {
  description = "Subnet proxy-only self-links."
  value       = local.tfvars.subnet_proxy_only_self_links
}

output "subnet_psc_self_links" {
  description = "Subnet PSC self-links."
  value       = local.tfvars.subnet_psc_self_links
}

output "vpc_self_links" {
  description = "VPC self-links."
  value       = local.tfvars.vpc_self_links
}
