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

locals {
  # leaving this here to document how to get self identity in a stage
  # automation_resman_sa = try(
  #   data.google_client_openid_userinfo.provider_identity[0].email, null
  # )
  # tag values use descriptive names
  identity_providers = coalesce(
    try(var.automation.federated_identity_providers, null), {}
  )
  principals = {
    for k, v in var.groups : k => (
      can(regex("^[a-zA-Z]+:", v))
      ? v
      : "group:${v}@${var.organization.domain}"
    )
  }
  root_node = (
    var.root_node == null
    ? "organizations/${var.organization.id}"
    : var.root_node
  )
  stage_service_accounts = merge(
    !var.fast_stage_2.networking.enabled ? {} : {
      networking   = module.net-sa-rw[0].email
      networking-r = module.net-sa-ro[0].email
    },
    !var.fast_stage_2.security.enabled ? {} : {
      security   = module.sec-sa-rw[0].email
      security-r = module.sec-sa-ro[0].email
    },
    !var.fast_stage_2.project_factory.enabled ? {} : {
      project-factory   = module.pf-sa-rw[0].email
      project-factory-r = module.pf-sa-ro[0].email
    },
    { for k, v in local.stage3 : k => module.stage3-sa-rw[k].email },
    { for k, v in local.stage3 : "${k}-r" => module.stage3-sa-ro[k].email },
  )
  tag_keys = (
    var.root_node == null
    ? module.organization[0].tag_keys
    : module.automation-project[0].tag_keys
  )
  tag_root = (
    var.root_node == null
    ? var.organization.id
    : var.automation.project_id
  )
  tag_values = (
    var.root_node == null
    ? module.organization[0].tag_values
    : module.automation-project[0].tag_values
  )
  top_level_folder_ids = {
    for k, v in module.top-level-folder : k => v.id
  }
  top_level_service_accounts = {
    for k, v in module.top-level-sa : k => try(v.email)
  }
}

# data "google_client_openid_userinfo" "provider_identity" {
#   count = length(local.cicd_repositories) > 0 ? 1 : 0
# }
