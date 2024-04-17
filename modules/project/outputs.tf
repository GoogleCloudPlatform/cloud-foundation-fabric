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

output "custom_role_id" {
  description = "Map of custom role IDs created in the project."
  value = {
    for k, v in google_project_iam_custom_role.roles :
    # build the string manually so that role IDs can be used as map
    # keys (useful for folder/organization/project-level iam bindings)
    (k) => "projects/${local.prefix}${var.name}/roles/${local.custom_roles[k].name}"
  }
}

output "custom_roles" {
  description = "Map of custom roles resources created in the project."
  value       = google_project_iam_custom_role.roles
}

output "id" {
  description = "Project id."
  value       = "${local.prefix}${var.name}"
  depends_on = [
    google_project.project,
    data.google_project.project,
    google_org_policy_policy.default,
    google_project_service.project_services,
    google_compute_shared_vpc_host_project.shared_vpc_host,
    google_compute_shared_vpc_service_project.shared_vpc_service,
    google_compute_shared_vpc_service_project.service_projects,
    google_project_iam_member.shared_vpc_host_robots,
    google_kms_crypto_key_iam_member.service_identity_cmek,
    google_project_service_identity.jit_si,
    google_project_service_identity.servicenetworking,
    google_project_iam_member.servicenetworking
  ]
}

output "name" {
  description = "Project name."
  value       = local.project.name
  depends_on = [
    google_org_policy_policy.default,
    google_project_service.project_services,
    google_compute_shared_vpc_service_project.service_projects,
    google_project_iam_member.shared_vpc_host_robots,
    google_kms_crypto_key_iam_member.service_identity_cmek
  ]
}

output "number" {
  description = "Project number."
  value       = local.project.number
  depends_on = [
    google_org_policy_policy.default,
    google_project_service.project_services,
    google_compute_shared_vpc_host_project.shared_vpc_host,
    google_compute_shared_vpc_service_project.shared_vpc_service,
    google_compute_shared_vpc_service_project.service_projects,
    google_project_iam_member.shared_vpc_host_robots,
    google_kms_crypto_key_iam_member.service_identity_cmek,
    google_project_service_identity.jit_si,
    google_project_service_identity.servicenetworking,
    google_project_iam_member.servicenetworking
  ]
}

# TODO: deprecate in favor of id

output "project_id" {
  description = "Project id."
  value       = "${local.prefix}${var.name}"
  depends_on = [
    google_project.project,
    data.google_project.project,
    google_org_policy_policy.default,
    google_project_service.project_services,
    google_compute_shared_vpc_host_project.shared_vpc_host,
    google_compute_shared_vpc_service_project.shared_vpc_service,
    google_compute_shared_vpc_service_project.service_projects,
    google_project_iam_member.shared_vpc_host_robots,
    google_kms_crypto_key_iam_member.service_identity_cmek,
    google_project_service_identity.jit_si,
    google_project_service_identity.servicenetworking,
    google_project_iam_member.servicenetworking
  ]
}

output "quota_configs" {
  description = "Quota configurations."
  value = {
    for k, v in google_cloud_quotas_quota_preference.default :
    k => {
      granted   = v.quota_config[0].granted_value
      preferred = v.quota_config[0].preferred_value
    }
  }
}

output "quotas" {
  description = "Quota resources."
  value       = google_cloud_quotas_quota_preference.default
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
    google_kms_crypto_key_iam_member.service_identity_cmek,
    google_project_service_identity.jit_si,
    data.google_bigquery_default_service_account.bq_sa,
    data.google_storage_project_service_account.gcs_sa
  ]
}

output "services" {
  description = "Service APIs to enabled in the project."
  value       = var.services
  depends_on = [
    google_project_service.project_services,
    google_project_service_identity.jit_si,
  ]
}

output "sink_writer_identities" {
  description = "Writer identities created for each sink."
  value = {
    for name, sink in google_logging_project_sink.sink : name => sink.writer_identity
  }
}

output "tag_keys" {
  description = "Tag key resources."
  value = {
    for k, v in google_tags_tag_key.default : k => v if(
      v.purpose == null || v.purpose == ""
    )
  }
}

output "tag_values" {
  description = "Tag value resources."
  value = {
    for k, v in google_tags_tag_value.default :
    k => v if !local.tag_values[k].tag_network
  }
}
