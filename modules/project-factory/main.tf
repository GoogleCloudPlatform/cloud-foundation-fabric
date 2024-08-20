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

# tfdoc:file:description Projects and billing budgets factory resources.

locals {
  context = {
    folder_ids = merge(
      var.factories_config.context.folder_ids,
      local.hierarchy
    )
    iam_principals = merge(
      var.factories_config.context.iam_principals,
      {
        for k, v in module.automation-service-accounts :
        k => v.iam_email
      }
    )
  }
}

module "projects" {
  source          = "../project"
  for_each        = local.projects
  billing_account = each.value.billing_account
  name            = each.key
  parent = lookup(
    local.context.folder_ids, each.value.parent, each.value.parent
  )
  prefix              = each.value.prefix
  auto_create_network = try(each.value.auto_create_network, false)
  compute_metadata    = try(each.value.compute_metadata, {})
  # TODO: concat lists for each key
  contacts = merge(
    each.value.contacts, var.data_merges.contacts
  )
  default_service_account = try(each.value.default_service_account, "keep")
  descriptive_name        = try(each.value.descriptive_name, null)
  iam = {
    for k, v in lookup(each.value, "iam", {}) : k => [
      for vv in v : try(
        # automation service account
        local.context.iam_principals["${each.key}/${vv}"],
        # other context
        local.context.iam_principals[vv],
        # passthrough
        vv
      )
    ]
  }
  iam_bindings = {
    for k, v in lookup(each.value, "iam_bindings", {}) : k => merge(v, {
      members = [
        for vv in v.members : try(
          # automation service account
          local.context.iam_principals["${each.key}/${vv}"],
          # other context
          local.context.iam_principals[vv],
          # passthrough
          vv
        )
      ]
    })
  }
  iam_bindings_additive = {
    for k, v in lookup(each.value, "iam_bindings_additive", {}) : k => merge(v, {
      member = try(
        # automation service account
        local.context.iam_principals["${each.key}/${v.member}"],
        # other context
        local.context.iam_principals[v.member],
        # passthrough
        v.member
      )
    })
  }
  # IAM by principals would trigger dynamic key errors so we don't interpolate
  iam_by_principals = try(each.value.iam_by_principals, {})
  labels = merge(
    each.value.labels, var.data_merges.labels
  )
  lien_reason         = try(each.value.lien_reason, null)
  logging_data_access = try(each.value.logging_data_access, {})
  logging_exclusions  = try(each.value.logging_exclusions, {})
  logging_sinks       = try(each.value.logging_sinks, {})
  metric_scopes = distinct(concat(
    each.value.metric_scopes, var.data_merges.metric_scopes
  ))
  org_policies = each.value.org_policies
  service_encryption_key_ids = merge(
    each.value.service_encryption_key_ids,
    var.data_merges.service_encryption_key_ids
  )
  services = distinct(concat(
    each.value.services,
    var.data_merges.services
  ))
  shared_vpc_host_config = each.value.shared_vpc_host_config
  shared_vpc_service_config = (
    try(each.value.shared_vpc_service_config.host_project, null) == null
    ? null
    : merge(each.value.shared_vpc_service_config, {
      host_project = lookup(
        var.factories_config.context.vpc_host_projects,
        each.value.shared_vpc_service_config.host_project,
        each.value.shared_vpc_service_config.host_project
      )
      network_users = [
        for v in try(each.value.shared_vpc_service_config.network_users, []) :
        lookup(local.context.iam_principals, v, v)
      ]
      # TODO: network subnet users
    })
  )
  tag_bindings = {
    for k, v in merge(each.value.tag_bindings, var.data_merges.tag_bindings) :
    k => lookup(var.factories_config.context.tag_values, v, v)
  }
  vpc_sc = each.value.vpc_sc
}

module "service-accounts" {
  source = "../iam-service-account"
  for_each = {
    for k in local.service_accounts : "${k.project}/${k.name}" => k
  }
  project_id   = module.projects[each.value.project].project_id
  name         = each.value.name
  display_name = each.value.display_name
  iam_project_roles = merge(
    {
      for k, v in each.value.iam_project_roles :
      lookup(var.factories_config.context.vpc_host_projects, k, k) => v
    },
    each.value.iam_self_roles == null ? {} : {
      (module.projects[each.value.project].project_id) = each.value.iam_self_roles
    }
  )
}

module "billing-account" {
  source = "../billing-account"
  count  = var.factories_config.budgets == null ? 0 : 1
  id     = var.factories_config.budgets.billing_account
  budget_notification_channels = (
    var.factories_config.budgets.notification_channels
  )
  budgets = local.budgets
}
