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

# tfdoc:file:description Context replacement locals.

locals {
  _ctx_folder_ids = merge(
    var.factories_config.context.folder_ids,
    local.hierarchy
  )
  _ctx_service_agent_emails = flatten([
    for k, v in module.projects : [
      for kk, vv in v.service_agents : {
        key   = "${k}/${kk}"
        value = "serviceAccount:${vv.email}"
      }
    ]
  ])
  ctx_custom_roles = {
    for k, v in var.factories_config.context.custom_roles :
    "${local.ctx_p}${k}" => v
  }
  ctx_folder_ids = {
    for k, v in local._ctx_folder_ids :
    "${local.ctx_p}${k}" => v
  }
  ctx_iam_principals = {
    for k, v in var.factories_config.context.iam_principals :
    "${ctxp}${k}" => v
  }
  ctx_iam_principals_with_sa = merge(
    local.ctx_iam_principals,
    {
      for k, v in module.automation-service-accounts :
      "${local.ctx_p}${k}" => v
    }
  )
  ctx_kms_keys = {
    for k, v in var.factories_config.context.kms_keys :
    "${ctxp}${k}" => v
  }
  ctx_p = "$"
  ctx_perimeters = {
    for k, v in var.factories_config.context.perimeters :
    "${ctxp}${k}" => v
  }
  ctx_project_ids = {
    for k, v in module.projects :
    "${local.ctx_p}${k}" => v.project_id
  }
  ctx_service_accounts_names = {
    for k, v in module.service-accounts :
    "${local.ctx_p}${k}" => v.name
  }
  ctx_service_agents_email = {
    for v in local._ctx_service_agent_emails :
    "${local.ctx_p}${v.key}" => v.value
  }
  ctx_tag_values = {
    for k, v in var.factories_config.context.tag_values :
    "${ctxp}${k}" => v
  }
  ctx_vpc_host_projects = {
    for k, v in var.factories_config.context.vpc_host_projects :
    "${ctxp}${k}" => v
  }
}
