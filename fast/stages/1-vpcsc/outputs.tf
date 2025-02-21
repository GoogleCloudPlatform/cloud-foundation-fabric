/**
 * Copyright 2024 Google LLC
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
    perimeters = {
      for k, v in try(module.vpc-sc[0].service_perimeters_regular, {}) :
      k => v.id
    }
    perimeters_bridge = {
      for k, v in try(module.vpc-sc[0].service_perimeters_bridge, {}) :
      k => v.id
    }
  }
}

resource "local_file" "tfvars" {
  for_each        = var.outputs_location == null ? {} : { 1 = 1 }
  file_permission = "0644"
  filename        = "${pathexpand(var.outputs_location)}/tfvars/1-vpcsc.auto.tfvars.json"
  content         = jsonencode(local.tfvars)
}

resource "google_storage_bucket_object" "tfvars" {
  bucket  = var.automation.outputs_bucket
  name    = "tfvars/1-vpcsc.auto.tfvars.json"
  content = jsonencode(local.tfvars)
}

output "tfvars" {
  description = "Terraform variable files for the following stages."
  sensitive   = true
  value       = local.tfvars
}

output "vpc_sc_perimeter_default" {
  description = "Raw default perimeter resource."
  sensitive   = true
  value       = try(module.vpc-sc[0].service_perimeters_regular["default"], null)
}
