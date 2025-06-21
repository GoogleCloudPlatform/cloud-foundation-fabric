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