/**
 * Copyright 2021 Google LLC
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

output "project_id" {
  description = "Project id."
  value       = "${local.prefix}${var.name}"
  depends_on = [
    google_project.project,
    data.google_project.project,
    google_project_organization_policy.boolean,
    google_project_organization_policy.list,
    google_project_service.project_services,
    google_compute_shared_vpc_service_project.service_projects,
    google_kms_crypto_key_iam_member.crypto_key
  ]
}

output "name" {
  description = "Project name."
  value       = local.project.name
  depends_on = [
    google_project_organization_policy.boolean,
    google_project_organization_policy.list,
    google_project_service.project_services,
    google_compute_shared_vpc_service_project.service_projects,
    google_kms_crypto_key_iam_member.crypto_key
  ]
}

output "number" {
  description = "Project number."
  value       = local.project.number
  depends_on = [
    google_project_organization_policy.boolean,
    google_project_organization_policy.list,
    google_project_service.project_services,
    google_compute_shared_vpc_service_project.service_projects,
    google_kms_crypto_key_iam_member.crypto_key
  ]
}

output "service_accounts" {
  description = "Product robot service accounts in project."
  value = {
    cloud_services = local.service_account_cloud_services
    default        = local.service_accounts_default
    robots         = local.service_accounts_robots
  }
  depends_on = [
    google_project_service.project_services,
    google_kms_crypto_key_iam_member.crypto_key,
    google_project_service_identity.jit_si
  ]
}

output "custom_roles" {
  description = "Ids of the created custom roles."
  value = {
    for name, role in google_project_iam_custom_role.roles :
    name => role.id
  }
}

output "sink_writer_identities" {
  description = "Writer identities created for each sink."
  value = {
    for name, sink in google_logging_project_sink.sink : name => sink.writer_identity
  }
}
