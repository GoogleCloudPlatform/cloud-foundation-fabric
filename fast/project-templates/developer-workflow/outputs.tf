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

output "group_emails" {
  description = "Emails of the created groups."
  value = {
    developers = "group:gcp-developers@${var.organization.domain}"
    approvers  = "group:gcp-organization-admins@${var.organization.domain}"
  }
}

output "project_ids" {
  description = "Project IDs of the created projects."
  value = {
    for k, v in module.project : k => v.project_id
  }
}
