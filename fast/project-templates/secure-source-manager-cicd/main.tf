/**
 * Copyright 2026 Google LLC
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

locals {
  # context expansion happens here, once, for every value the template or
  # its modules consume: modules receive resolved values, not references
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local.ctx_p}${k}:${kk}" => vv
    }
  }
  ctx_p = "$"
  # the principal running this configuration, which SSM checks for actAs
  # on each repository service account; derived from the provider identity
  # unless passed in, so plan tests can avoid the data source
  automation_principal = (
    var.projects_config.ssm.automation_principal == null
    ? "serviceAccount:${data.google_client_openid_userinfo.provider_identity[0].email}"
    : lookup(
      local.ctx.iam_principals,
      var.projects_config.ssm.automation_principal,
      var.projects_config.ssm.automation_principal
    )
  )
  build_project_id = (
    var.projects_config.build == null
    ? local.ssm_project_id
    : lookup(
      local.ctx.project_ids,
      var.projects_config.build.project_id,
      var.projects_config.build.project_id
    )
  )
  ca_pool_id = (
    var.ssm_config.ca_pool_id == null
    ? null
    : lookup(
      local.ctx.ca_pools, var.ssm_config.ca_pool_id, var.ssm_config.ca_pool_id
    )
  )
  lb_network = lookup(
    local.ctx.networks,
    var.load_balancer_config.network,
    var.load_balancer_config.network
  )
  lb_subnetwork = lookup(
    local.ctx.subnets,
    var.load_balancer_config.subnetwork,
    var.load_balancer_config.subnetwork
  )
  location = lookup(local.ctx.locations, var.location, var.location)
  peered_network = lookup(
    local.ctx.networks,
    var.build_pool_config.peered_network,
    var.build_pool_config.peered_network
  )
  prefix = var.prefix == null ? "" : "${var.prefix}-"
  psc_allowed_projects = (
    var.ssm_config.psc_allowed_projects == null
    ? null
    : [
      for p in var.ssm_config.psc_allowed_projects :
      lookup(local.ctx.project_ids, p, p)
    ]
  )
  ssm_project_id = lookup(
    local.ctx.project_ids,
    var.projects_config.ssm.project_id,
    var.projects_config.ssm.project_id
  )
}

data "google_client_openid_userinfo" "provider_identity" {
  count = var.projects_config.ssm.automation_principal == null ? 1 : 0
}

module "ssm-project" {
  source = "../../../modules/project"
  name   = local.ssm_project_id
  prefix = null
  project_reuse = {
    use_data_source = false
    attributes = {
      name             = local.ssm_project_id
      number           = var.projects_config.ssm.number
      services_enabled = ["securesourcemanager.googleapis.com"]
    }
  }
  service_agents_config = {
    create_primary_agents = false
    grant_default_roles   = false
  }
}
