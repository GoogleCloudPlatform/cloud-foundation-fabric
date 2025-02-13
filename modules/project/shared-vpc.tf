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

# tfdoc:file:description Shared VPC project-level configuration.

locals {
  _svpc = var.shared_vpc_service_config
  # read the list of service/roles for API service agents
  _svpc_agent_config = yamldecode(file(
    "${path.module}/sharedvpc-agent-iam.yaml"
  ))
  # filter the list and keep services for which we need to create IAM bindings
  _svpc_agent_config_filtered = [
    for v in local._svpc_agent_config : v
    if contains(local._svpc.service_iam_grants, v.service)
  ]
  # normalize the list of service/role tuples
  _svpc_agent_grants = flatten(flatten([
    for v in local._svpc_agent_config_filtered : [
      for service, roles in v.agents : [
        for role in roles : { role = role, service = service }
      ]
    ]
  ]))
  # normalize the service identity IAM bindings directly defined by the user
  _svpc_service_iam = flatten([
    for role, services in local._svpc.service_agent_iam : [
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
  # combine the two sets of service/role bindings defined above
  svpc_service_iam = {
    for b in setunion(local._svpc_service_iam, local._svpc_agent_grants) :
    "${b.role}:${b.service}" => b
  }
  # normalize the service identity subnet IAM bindings
  _svpc_service_subnet_iam = flatten([
    for subnet, services in local._svpc.service_agent_subnet_iam : [
      for service in services : [{
        region  = split("/", subnet)[0]
        subnet  = split("/", subnet)[1]
        service = service
      }]
    ]
  ])
  svpc_service_subnet_iam = {
    for v in local._svpc_service_subnet_iam :
    "${v.region}:${v.subnet}:${v.service}" => v
  }
  # normalize the network user subnet IAM binding
  _svpc_network_user_subnet_iam = (
    local._svpc.network_subnet_users == null || local._svpc.host_project == null
    ? []
    : flatten([
      for subnet, members in local._svpc.network_subnet_users : [
        for member in members : {
          region = split("/", subnet)[0]
          subnet = split("/", subnet)[1]
          member = member
        }
      ]
    ])
  )
  svpc_network_user_subnet_iam = {
    for v in local._svpc_network_user_subnet_iam :
    "${v.region}:${v.subnet}:${v.member}" => v
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
  member   = try(local.aliased_service_agents[each.value.service].iam_email, each.value.service)
  depends_on = [
    google_project_service.project_services,
    google_project_service_identity.default,
    google_project_default_service_accounts.default_service_accounts,
    data.google_bigquery_default_service_account.bq_sa,
    data.google_storage_project_service_account.gcs_sa,
  ]
}

resource "google_project_iam_member" "shared_vpc_host_iam" {
  for_each   = toset(var.shared_vpc_service_config.network_users)
  project    = var.shared_vpc_service_config.host_project
  role       = "roles/compute.networkUser"
  member     = each.value
  depends_on = []
}

resource "google_compute_subnetwork_iam_member" "shared_vpc_host_robots" {
  for_each   = local.svpc_service_subnet_iam
  project    = var.shared_vpc_service_config.host_project
  region     = each.value.region
  subnetwork = each.value.subnet
  role       = "roles/compute.networkUser"
  member     = try(local.aliased_service_agents[each.value.service].iam_email, each.value.service)
  depends_on = [
    google_project_service.project_services,
    google_project_service_identity.default,
    google_project_default_service_accounts.default_service_accounts,
    data.google_bigquery_default_service_account.bq_sa,
    data.google_storage_project_service_account.gcs_sa,
  ]
}

resource "google_compute_subnetwork_iam_member" "shared_vpc_host_subnets_iam" {
  for_each   = local.svpc_network_user_subnet_iam
  project    = var.shared_vpc_service_config.host_project
  region     = each.value.region
  subnetwork = each.value.subnet
  role       = "roles/compute.networkUser"
  member     = each.value.member
}
