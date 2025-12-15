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

output "alert_ids" {
  description = "Monitoring alert IDs."
  value = {
    for k, v in google_monitoring_alert_policy.alerts :
    k => v.id
  }
}

output "bigquery_reservations" {
  description = "BigQuery reservations and assignments."
  value = {
    reservations = google_bigquery_reservation.default
    assignments  = local.bigquery_reservations_assigments
  }
}

output "custom_role_id" {
  description = "Map of custom role IDs created in the project."
  value       = local.custom_role_ids
}

output "custom_roles" {
  description = "Map of custom roles resources created in the project."
  value       = google_project_iam_custom_role.roles
}

output "default_service_accounts" {
  description = "Emails of the default service accounts for this project."
  value = {
    compute = "${local.project.number}-compute@developer.gserviceaccount.com"
    gae     = "${local.project.project_id}@appspot.gserviceaccount.com"
  }
}

output "id" {
  description = "Project id."
  value       = local.project_id
  depends_on = [
    google_project.project,
    data.google_project.project,
    google_org_policy_policy.default,
    google_project_service.project_services,
    google_compute_shared_vpc_host_project.shared_vpc_host,
    google_compute_shared_vpc_service_project.shared_vpc_service,
    google_compute_shared_vpc_service_project.service_projects,
    google_project_iam_member.shared_vpc_host_robots,
    google_kms_crypto_key_iam_member.service_agent_cmek,
    google_project_service_identity.default,
    google_project_iam_member.service_agents
  ]
}

output "kms_autokeys" {
  description = "KMS Autokey key ids."
  value = {
    for k, v in google_kms_key_handle.default : k => v.kms_key
  }
}

output "name" {
  description = "Project name."
  value       = local.project.name
  depends_on = [
    google_org_policy_policy.default,
    google_project_service.project_services,
    google_compute_shared_vpc_service_project.service_projects,
    google_project_iam_member.shared_vpc_host_robots,
    google_kms_crypto_key_iam_member.service_agent_cmek,
  ]
}

output "network_tag_keys" {
  description = "Tag key resources."
  value = {
    for k, v in google_tags_tag_key.default : k => v if(
      v.purpose != null && v.purpose != ""
    )
  }
}

output "network_tag_values" {
  description = "Tag value resources."
  value = {
    for k, v in google_tags_tag_value.default :
    k => v if try(local.tag_values[k].tag_network, null) != null
  }
}

output "notification_channel_names" {
  description = "Notification channel names."
  value = {
    for k, v in google_monitoring_notification_channel.channels :
    k => v.name
  }
}

output "notification_channels" {
  description = "Full notification channel objects."
  value       = google_monitoring_notification_channel.channels
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
    google_kms_crypto_key_iam_member.service_agent_cmek,
    google_project_service_identity.default,
    google_project_iam_member.service_agents
  ]
}
output "organization_policies_ids" {
  description = "Map of ORGANIZATION_POLICIES => ID in the organization."
  value       = { for k, v in google_org_policy_policy.default : k => v.id }
}

# TODO: deprecate in favor of id

output "project_id" {
  description = "Project id."
  value       = local.project_id
  depends_on = [
    google_project.project,
    data.google_project.project,
    google_org_policy_policy.default,
    google_project_service.project_services,
    google_compute_shared_vpc_host_project.shared_vpc_host,
    google_compute_shared_vpc_service_project.shared_vpc_service,
    google_compute_shared_vpc_service_project.service_projects,
    google_project_iam_member.shared_vpc_host_robots,
    google_kms_crypto_key_iam_member.service_agent_cmek,
    google_project_service_identity.default,
    google_project_iam_member.service_agents
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

output "scc_custom_sha_modules_ids" {
  description = "Map of SCC CUSTOM SHA MODULES => ID in the project."
  value       = { for k, v in google_scc_management_project_security_health_analytics_custom_module.scc_project_custom_module : k => v.id }
}

output "service_agents" {
  description = "List of all (active) service agents for this project."
  value       = local.aliased_service_agents
  depends_on = [
    google_project_service_identity.default,
    google_project_iam_member.service_agents
  ]
}

output "services" {
  description = "Service APIs to enable in the project."
  value       = local.available_services
  depends_on = [
    google_project_service.project_services,
    google_project_service_identity.default,
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
    k => v if try(local.tag_values[k].tag_network, null) == null
  }
}

output "workload_identity_pool_ids" {
  description = "Workload identity provider ids."
  value = {
    for k, v in google_iam_workload_identity_pool.default : k => v.name
  }
}

output "workload_identity_provider_ids" {
  description = "Workload identity provider attributes."
  value = {
    for k, v in google_iam_workload_identity_pool_provider.default :
    k => v.name
  }
}

output "workload_identity_providers" {
  description = "Workload identity provider attributes."
  value = {
    for k, v in local.wif_providers : k => {
      name = google_iam_workload_identity_pool_provider.default[k].name
      pool = google_iam_workload_identity_pool.default[v.pool].name
      type = try(v.identity_provider.oidc.template, null)
    }
  }
}
