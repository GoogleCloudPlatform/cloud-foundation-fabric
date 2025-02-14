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
  project_outputs = {
    for k, v in module.projects.projects : k => {
      bucket = try(
        v.automation_buckets["state"],
        v.automation_buckets["tf-state"],
        null
      )
      project_id = v.project_id
      sa         = try(v.automation_service_accounts["rw"], null)
      sa_ro      = try(v.automation_service_accounts["ro"], null)
    } if v.automation_enabled
  }
}

output "projects" {
  description = "Created projects."
  value = {
    for k, v in module.projects.projects : k => {
      id     = v.project_id
      number = v.number
      automation = {
        buckets          = v.automation_buckets
        service_accounts = v.automation_service_accounts
      }
    }
  }
}

output "service_accounts" {
  description = "Created service accounts."
  value = {
    for k, v in module.projects.service_accounts : k => {
      email      = v.email
      iam_emanil = v.iam_email
    }
  }
}

# generate tfvars file for subsequent stages

resource "local_file" "providers" {
  for_each = var.outputs_location == null ? {} : {
    for k, v in local.project_outputs : k => v
    if v.bucket != null && v.sa != null
  }
  file_permission = "0644"
  filename        = "${try(pathexpand(var.outputs_location), "")}/providers/${var.stage_name}/${each.key}-providers.tf"
  content         = templatefile("templates/providers.tf.tpl", each.value)
}

resource "google_storage_bucket_object" "tfvars" {
  for_each = var.outputs_location == null ? {} : {
    for k, v in local.project_outputs : k => v
    if v.bucket != null && v.sa != null
  }
  bucket  = var.automation.outputs_bucket
  name    = "providers/${var.stage_name}/${each.key}-providers.tf"
  content = templatefile("templates/providers.tf.tpl", each.value)
}
