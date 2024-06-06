# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# tfdoc:file:description Output variables.

locals {
  tfvars = {
    project_ids = {
      gcve-dev = module.gcve-pc.project_id
    }
    vmw_engine_network_config   = module.gcve-pc.vmw_engine_network_config
    vmw_engine_network_peerings = module.gcve-pc.vmw_engine_network_peerings
    vmw_engine_private_clouds   = module.gcve-pc.vmw_engine_private_clouds
    vmw_private_cloud_network   = module.gcve-pc.vmw_private_cloud_network
  }
}

# generate tfvars file for subsequent stages

resource "local_file" "tfvars" {
  for_each        = var.outputs_location == null ? {} : { 1 = 1 }
  file_permission = "0644"
  filename        = "${pathexpand(var.outputs_location)}/tfvars/3-gcve-dev.auto.tfvars.json"
  content         = jsonencode(local.tfvars)
}

resource "google_storage_bucket_object" "tfvars" {
  bucket  = var.automation.outputs_bucket
  name    = "tfvars/3-gcve-dev.auto.tfvars.json"
  content = jsonencode(local.tfvars)
}

# outputs

output "project_id" {
  description = "GCVE project id."
  value       = module.gcve-pc.project_id
}

output "vmw_engine_network_config" {
  description = "VMware engine network configuration."
  value       = module.gcve-pc.vmw_engine_network_config
}

output "vmw_engine_network_peerings" {
  description = "The peerings created towards the user VPC or other VMware engine networks."
  value       = module.gcve-pc.vmw_engine_network_peerings
}

output "vmw_engine_private_clouds" {
  description = "VMware engine private cloud resources."
  value       = module.gcve-pc.vmw_engine_private_clouds
}

output "vmw_private_cloud_network" {
  description = "VMware engine network."
  value       = module.gcve-pc.vmw_private_cloud_network
}

