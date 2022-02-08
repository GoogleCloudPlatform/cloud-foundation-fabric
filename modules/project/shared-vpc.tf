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

# tfdoc:file:description Shared VPC project-level configuration.

locals {
  # compute the host project IAM bindings for this project's service identities
  _svpc_service_iam = flatten([
    for role, services in var.shared_vpc_service_config.service_identity_iam : [
      for service in services : {
        role    = role
        service = service
      }
    ]
  ])
  svpc_service_iam = {
    for b in local._svpc_service_iam : "${b.role}:${b.service}" => b
  }
}

resource "google_compute_shared_vpc_host_project" "shared_vpc_host" {
  provider = google-beta
  count    = try(var.shared_vpc_host_config.enabled, false) ? 1 : 0
  project  = local.project.project_id
}

resource "google_compute_shared_vpc_service_project" "service_projects" {
  provider = google-beta
  for_each = (
    try(var.shared_vpc_host_config.enabled, false)
    ? toset(coalesce(var.shared_vpc_host_config.service_projects, []))
    : toset([])
  )
  host_project    = local.project.project_id
  service_project = each.value
  depends_on      = [google_compute_shared_vpc_host_project.shared_vpc_host]
}

resource "google_compute_shared_vpc_service_project" "shared_vpc_service" {
  provider        = google-beta
  count           = try(var.shared_vpc_service_config.attach, false) ? 1 : 0
  host_project    = var.shared_vpc_service_config.host_project
  service_project = local.project.project_id
}

resource "google_project_iam_member" "shared_vpc_host_robots" {
  for_each = local.svpc_service_iam
  project  = var.shared_vpc_service_config.host_project
  role     = each.value.role
  member = (
    each.value.service == "cloudservices"
    ? local.service_account_cloud_services
    : local.service_accounts_robots[each.value.service]
  )
}

