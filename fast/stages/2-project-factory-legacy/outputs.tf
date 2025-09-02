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
  project_provider_data = flatten([
    for k, v in module.projects.projects : [
      for sk, sv in try(v.automation.service_accounts) : {
        key             = "${k}-${sk}"
        bucket          = try(v.automation.bucket, null)
        project_id      = v.project_id
        project_number  = v.number
        service_account = sv
      }
    ] if try(v.automation.bucket, null) != null
  ])
}

output "buckets" {
  description = "Created buckets."
  value = {
    for k, v in module.projects.buckets : k => v
  }
}

output "projects" {
  description = "Created projects."
  value = {
    for k, v in module.projects.projects : k => {
      id             = v.project_id
      number         = v.number
      automation     = v.automation
      service_agents = v.service_agents
    }
  }
}

output "service_accounts" {
  description = "Created service accounts."
  value = {
    for k, v in module.projects.service_accounts : k => {
      email     = v.email
      iam_email = v.iam_email
    }
  }
}

resource "google_storage_bucket_object" "version" {
  count  = fileexists("fast_version.txt") ? 1 : 0
  bucket = var.automation.outputs_bucket
  name   = "versions/2-project-factory-version.txt"
  source = "fast_version.txt"
}

# generate tfvars file for subsequent stages

resource "local_file" "providers" {
  for_each        = var.outputs_location == null ? {} : { for v in local.project_provider_data : v.key => v }
  file_permission = "0644"
  filename        = "${pathexpand(var.outputs_location)}/providers/${var.stage_name}/${each.key}-providers.tf"
  content         = templatefile("templates/providers.tf.tpl", each.value)
}

resource "google_storage_bucket_object" "tfvars" {
  for_each = { for v in local.project_provider_data : v.key => v }
  bucket   = var.automation.outputs_bucket
  name     = "providers/${var.stage_name}/${each.key}-providers.tf"
  content  = templatefile("templates/providers.tf.tpl", each.value)
}
