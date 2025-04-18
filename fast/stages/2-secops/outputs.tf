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
    federated_identity_pool = try(
      google_iam_workforce_pool.default[0].name, null
    )
    secops_project_ids = {
      for k, v in module.project : k => v.id
    }
  }
}

resource "local_file" "tfvars" {
  for_each        = var.outputs_location == null ? {} : { 1 = 1 }
  file_permission = "0644"
  filename        = "${pathexpand(var.outputs_location)}/tfvars/2-secops.auto.tfvars.json"
  content         = jsonencode(local.tfvars)
}

resource "google_storage_bucket_object" "tfvars" {
  bucket  = var.automation.outputs_bucket
  name    = "tfvars/2-security.auto.tfvars.json"
  content = jsonencode(local.tfvars)
}

output "federated_identity_pool" {
  description = "Workforce Identity Federation pool."
  value       = local.tfvars.federated_identity_pool
}

output "secops_project_ids" {
  description = "SecOps project IDs."
  value       = local.tfvars.secops_project_ids
}

output "tfvars" {
  description = "Terraform variable files for the following stages."
  sensitive   = true
  value       = local.tfvars
}
