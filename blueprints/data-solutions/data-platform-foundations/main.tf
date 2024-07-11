# Copyright 2024 Google LLC
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
      "load-robot-df", "load-sa-df-worker",
      "orch-cloudservices", "orch-robot-df", "orch-robot-gke",
      "transf-robot-df", "transf-sa-df-worker",
    ]
    "roles/composer.sharedVpcAgent" = [
      "orch-robot-cs"
    ]
    "roles/container.hostServiceAgentUser" = [
      "orch-robot-df", "orch-robot-gke"
    ]
  }
  groups = {
    for k, v in var.groups : k => "${v}@${var.organization_domain}"
  }
  groups_iam = {
    for k, v in local.groups : k => "group:${v}"
  }
  iam_principals = {
    data_analysts        = "group:${local.groups.data-analysts}"
    data_engineers       = "group:${local.groups.data-engineers}"
    data_security        = "group:${local.groups.data-security}"
    robots_cloudbuild    = module.orch-project.service_agents.cloudbuild.iam_email
    robots_composer      = module.orch-project.service_agents.composer.iam_email
    robots_dataflow_load = module.load-project.service_agents.dataflow.iam_email
    robots_dataflow_trf  = module.transf-project.service_agents.dataflow.iam_email
    sa_df_build          = module.orch-sa-df-build.iam_email
    sa_drop_bq           = module.drop-sa-bq-0.iam_email
    sa_drop_cs           = module.drop-sa-cs-0.iam_email
    sa_drop_ps           = module.drop-sa-ps-0.iam_email
    sa_load              = module.load-sa-df-0.iam_email
    sa_orch              = module.orch-sa-cmp-0.iam_email
    sa_transf_bq         = module.transf-sa-bq-0.iam_email,
    sa_transf_df         = module.transf-sa-df-0.iam_email,
  }
  project_suffix     = var.project_suffix == null ? "" : "-${var.project_suffix}"
  shared_vpc_project = try(var.network_config.host_project, null)
  # this is needed so that for_each only uses static values
  shared_vpc_role_members = {
    load-robot-df       = module.load-project.service_agents.dataflow.iam_email
    load-sa-df-worker   = module.load-sa-df-0.iam_email
    orch-cloudservices  = module.orch-project.service_agents.cloudservices.iam_email
    orch-robot-cs       = module.orch-project.service_agents.composer.iam_email
    orch-robot-df       = module.orch-project.service_agents.dataflow.iam_email
    orch-robot-gke      = module.orch-project.service_agents.container-engine.iam_email
    transf-robot-df     = module.transf-project.service_agents.dataflow.iam_email
    transf-sa-df-worker = module.transf-sa-df-0.iam_email
  }
  # reassemble in a format suitable for for_each
  shared_vpc_bindings_map = {
    for binding in flatten([
      for role, members in local._shared_vpc_bindings : [
        for member in members : { role = role, member = member }
      ]
    ]) : "${binding.role}-${binding.member}" => binding
  }
  use_projects   = !var.project_config.project_create
  use_shared_vpc = var.network_config != null
}

resource "google_project_iam_member" "shared_vpc" {
  for_each = local.use_shared_vpc ? local.shared_vpc_bindings_map : {}
  project  = var.network_config.host_project
  role     = each.value.role
  member   = lookup(local.shared_vpc_role_members, each.value.member)
}
