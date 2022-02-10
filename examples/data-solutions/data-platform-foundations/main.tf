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
  groups = {
    for k, v in var.groups : k => "${v}@${var.organization_domain}"
  }
  groups_iam = {
    for k, v in local.groups : k => "group:${v}"
  }
  service_encryption_keys = var.service_encryption_keys
  shared_vpc_project      = try(var.network_config.host_project, null)
  use_shared_vpc          = var.network_config != null
}

module "shared-vpc-project" {
  source         = "../../../modules/project"
  count          = use_shared_vpc ? 1 : 0
  project_id     = var.network_config.host_project
  project_create = false
  iam_additive = {
    "roles/compute.networkUser" = [
      # load Dataflow service agent and worker service account
      module.load-project.service_accounts.robots.dataflow,
      module.load-sa-df-0.iam_email,
      # orchestration Composer service agents
      module.orch-project.service_accounts.robots.cloudservices,
      module.orch-project.service_accounts.robots.container-engine,
      module.orch-project.service_accounts.robots.dataflow,
    ],
    "roles/composer.sharedVpcAgent" = [
      # orchestration Composer service agent
      module.orch-project.service_accounts.robots.composer
    ],
    "roles/container.hostServiceAgentUser" = [
      # orchestration Composer service agents
      module.orch-project.service_accounts.robots.dataflow,
    ]
  }
}
