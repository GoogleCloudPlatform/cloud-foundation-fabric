# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# tfdoc:file:description Core locals.

locals {
  # we cannot reference service accounts directly as they are dynamic
  _shared_vpc_bindings = {
    "roles/compute.networkUser" = [
      "processing-cloudservices", "processing-robot-compute", "orch-robot-gke"
    ]
    "roles/composer.sharedVpcAgent" = [
      "processing-robot-cs"
    ]
    "roles/container.hostServiceAgentUser" = [
      "orch-robot-gke"
    ]
  }
  groups = {
    for k, v in var.groups : k => "${v}@${var.organization_domain}"
  }
  groups_iam = {
    for k, v in local.groups : k => "group:${v}"
  }
  project_suffix     = var.project_suffix == null ? "" : "-${var.project_suffix}"
  shared_vpc_project = try(var.network_config.host_project, null)
  # this is needed so that for_each only uses static values
  shared_vpc_role_members = {
    processing-cloudservices = "serviceAccount:${module.processing-project.service_accounts.cloud_services}"
    orprocessingch-robot-cs  = "serviceAccount:${module.processing-project.service_accounts.robots.composer}"
    processing-robot-gke     = "serviceAccount:${module.processing-project.service_accounts.robots.container-engine}"
    processing-robot-compute = "serviceAccount:${module.processing-project.service_accounts.robots.compute}"
  }
  # reassemble in a format suitable for for_each
  shared_vpc_bindings_map = {
    for binding in flatten([
      for role, members in local._shared_vpc_bindings : [
        for member in members : { role = role, member = member }
      ]
    ]) : "${binding.role}-${binding.member}" => binding
  }
  use_shared_vpc = var.network_config.host_project != null
}

resource "google_project_iam_member" "shared_vpc" {
  for_each = local.use_shared_vpc ? local.shared_vpc_bindings_map : {}
  project  = var.network_config.host_project
  role     = each.value.role
  member   = lookup(local.shared_vpc_role_members, each.value.member)
}
