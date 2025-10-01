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

# VPC networks output
# output "vpcs" {
#   description = "VPC networks from the network factory."
#   value       = module.network_factory.vpcs
# }

# Basic context output (simplified for now)
# output "network_configs" {
#   description = "Network configurations from factory."
#   value       = module.network_factory.context
# }

# Projects output (commented out since project_factory is commented out)
# output "projects" {
#   description = "Projects created by the project factory."
#   value       = module.project_factory.projects
# }

# Network context for downstream stages (simplified)
# output "network_context" {
#   description = "Network-specific context for downstream stages."
#   value = module.network_factory.context
# }

# TFVARS file location output
output "tfvars" {
  description = "Location of generated .tfvars files for downstream stages."
  value = {
    enabled = var.output_files.enabled
    local_path = var.output_files.enabled ? abspath("${pathexpand(var.output_files.local_path)}/${var.stage_name}.auto.tfvars.json") : null
    storage_bucket = var.output_files.storage_bucket
  }
}

