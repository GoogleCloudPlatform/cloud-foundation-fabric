/**
 * Copyright 2023 Google LLC
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

# tfdoc:file:description Shared VPC project-level configuration.

locals {
  _shared_vpc_agent_config = yamldecode(file("${path.module}/sharedvpc-agent-iam.yaml"))
  _shared_vpc_agent_config_filtered = [
    for config in local._shared_vpc_agent_config : config
    if contains(var.shared_vpc_service_config.service_iam_grants, config.service)
  ]
  _shared_vpc_agent_grants = flatten(flatten([
    for api in local._shared_vpc_agent_config_filtered : [
      for service, roles in api.agents : [
        for role in roles : { role = role, service = service }
      ]
    ]
  ]))

  # compute the host project IAM bindings for this project's service identities
  _svpc_service_iam = flatten([
    for role, services in var.shared_vpc_service_config.service_identity_iam : [
      for service in services : { role = role, service = service }
    ]
  ])
  svpc_host_config = {
    enabled = coalesce(
      try(var.shared_vpc_host_config.enabled, null), false
    )
    service_projects = coalesce(
      try(var.shared_vpc_host_config.service_projects, null), []
    )
  }

  svpc_service_iam = {
    for b in setunion(local._svpc_service_iam, local._shared_vpc_agent_grants) : "${b.role}:${b.service}" => b
  }
}

resource "google_compute_shared_vpc_host_project" "shared_vpc_host" {
  provider   = google-beta
  count      = local.svpc_host_config.enabled ? 1 : 0
  project    = local.project.project_id
  depends_on = [google_project_service.project_services]
}

resource "google_compute_shared_vpc_service_project" "service_projects" {
  provider        = google-beta
  for_each        = toset(local.svpc_host_config.service_projects)
  host_project    = local.project.project_id
  service_project = each.value
  depends_on      = [google_compute_shared_vpc_host_project.shared_vpc_host]
}

resource "google_compute_shared_vpc_service_project" "shared_vpc_service" {
  provider        = google-beta
  count           = var.shared_vpc_service_config.host_project != null ? 1 : 0
  host_project    = var.shared_vpc_service_config.host_project
  service_project = local.project.project_id
}

resource "google_project_iam_member" "shared_vpc_host_robots" {
  for_each = local.svpc_service_iam
  project  = var.shared_vpc_service_config.host_project
  role     = each.value.role
  member = (
    each.value.service == "cloudservices"
    ? "serviceAccount:${local.service_account_cloud_services}"
    : "serviceAccount:${local.service_accounts_robots[each.value.service]}"
  )
  depends_on = [
    google_project_service.project_services,
    google_project_service_identity.servicenetworking,
    google_project_service_identity.jit_si,
    google_project_default_service_accounts.default_service_accounts,
    data.google_bigquery_default_service_account.bq_sa,
    data.google_storage_project_service_account.gcs_sa,
  ]
}
