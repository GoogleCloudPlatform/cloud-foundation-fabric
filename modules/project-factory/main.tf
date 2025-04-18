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
      },
      # module.service-accounts are excluded here, as adding them here results in dependency cycles
    )
  }
}

module "projects" {
  source          = "../project"
  for_each        = local.projects
  billing_account = each.value.billing_account
  name            = each.value.name
  parent = lookup(
    local.context.folder_ids, each.value.parent, each.value.parent
  )
  prefix              = each.value.prefix
  alerts              = try(each.value.alerts, null)
  auto_create_network = try(each.value.auto_create_network, false)
  compute_metadata    = try(each.value.compute_metadata, {})
  # TODO: concat lists for each key
  contacts = merge(
    each.value.contacts, var.data_merges.contacts
  )
  default_service_account = try(each.value.default_service_account, "keep")
  descriptive_name        = try(each.value.descriptive_name, null)
  factories_config = {
    custom_roles  = each.value.factories_config.custom_roles
    observability = each.value.factories_config.observability
    org_policies  = each.value.factories_config.org_policies
    quotas        = each.value.factories_config.quotas
    context = {
      notification_channels = var.factories_config.context.notification_channels
    }
  }
  labels = merge(
    each.value.labels, var.data_merges.labels
  )
  lien_reason         = try(each.value.lien_reason, null)
  log_scopes          = try(each.value.log_scopes, null)
  logging_data_access = try(each.value.logging_data_access, {})
  logging_exclusions  = try(each.value.logging_exclusions, {})
  logging_metrics     = try(each.value.logging_metrics, null)
  logging_sinks       = try(each.value.logging_sinks, {})
  metric_scopes = distinct(concat(
    each.value.metric_scopes, var.data_merges.metric_scopes
  ))
  notification_channels = try(each.value.notification_channels, null)
  org_policies          = each.value.org_policies
  service_encryption_key_ids = merge(
    each.value.service_encryption_key_ids,
    var.data_merges.service_encryption_key_ids
  )
  services = distinct(concat(
    each.value.services,
    var.data_merges.services
  ))
  shared_vpc_host_config = each.value.shared_vpc_host_config
  tag_bindings = {
    for k, v in merge(each.value.tag_bindings, var.data_merges.tag_bindings) :
    k => lookup(var.factories_config.context.tag_values, v, v)
  }
  tags = each.value.tags
  vpc_sc = each.value.vpc_sc == null ? null : {
    perimeter_name = (
      each.value.vpc_sc.perimeter_name == null
      ? null
      : lookup(
        var.factories_config.context.perimeters,
        each.value.vpc_sc.perimeter_name,
        each.value.vpc_sc.perimeter_name
      )
    )
    perimeter_bridges = each.value.vpc_sc.perimeter_bridges
    is_dry_run        = each.value.vpc_sc.is_dry_run
  }
}

module "projects-iam" {
  source   = "../project"
  for_each = local.projects
  name     = module.projects[each.key].project_id
  project_reuse = {
    use_data_source = false
    project_attributes = {
      name             = module.projects[each.key].name
      number           = module.projects[each.key].number
      services_enabled = module.projects[each.key].services
    }
  }
  iam = {
    for k, v in lookup(each.value, "iam", {}) : k => [
      for vv in v : try(
        # project service accounts (sa)
        module.service-accounts["${each.key}/${vv}"].iam_email,
        # automation service account (rw)
        local.context.iam_principals["${each.key}/automation/${vv}"],
        # automation service account (automation/rw)
        local.context.iam_principals["${each.key}/${vv}"],
        # other projects service accounts (project/sa)
        module.service-accounts[vv].iam_email,
        # other automation service account (project/automation/rw)
        local.context.iam_principals[vv],
        # passthrough + error handling using tonumber until Terraform gets fail/raise function
        (
          strcontains(vv, ":")
          ? vv
          : tonumber("[Error] Invalid member: '${vv}' in project '${each.key}'")
        )
      )
    ]
  }
  iam_bindings = {
    for k, v in lookup(each.value, "iam_bindings", {}) : k => merge(v, {
      members = [
        for vv in v.members : try(
          # project service accounts (sa)
          module.service-accounts["${each.key}/${vv}"].iam_email,
          # automation service account (rw)
          local.context.iam_principals["${each.key}/automation/${vv}"],
          # automation service account (automation/rw)
          local.context.iam_principals["${each.key}/${vv}"],
          # other projects service accounts (project/sa)
          module.service-accounts[vv].iam_email,
          # other automation service account (project/automation/rw)
          local.context.iam_principals[vv],
          # passthrough + error handling using tonumber until Terraform gets fail/raise function
          (
            strcontains(vv, ":")
            ? vv
            : tonumber("[Error] Invalid member: '${vv}' in project '${each.key}'")
          )
        )
      ]
    })
  }
  iam_bindings_additive = {
    for k, v in lookup(each.value, "iam_bindings_additive", {}) : k => merge(v, {
      member = try(
        # project service accounts (sa)
        module.service-accounts["${each.key}/${v.member}"].iam_email,
        # automation service account (rw)
        local.context.iam_principals["${each.key}/automation/${v.member}"],
        # automation service account (automation/rw)
        local.context.iam_principals["${each.key}/${v.member}"],
        # other projects service accounts (project/sa)
        module.service-accounts[v.member].iam_email,
        # other automation service account (project/automation/rw)
        local.context.iam_principals[v.member],
        # passthrough + error handling using tonumber until Terraform gets fail/raise function
        (
          strcontains(v.member, ":")
          ? v.member
          : tonumber("[Error] Invalid member: '${v.member}' in project '${each.key}'")
        )
      )
    })
  }
  # IAM by principals would trigger dynamic key errors so we don't interpolate
  iam_by_principals = try(each.value.iam_by_principals, {})
  # Shared VPC configuration is done at stage 2, to avoid dependency cycle between project service accounts and
  # IAM grants done for those service accounts
  factories_config = {
    custom_roles = each.value.factories_config.custom_roles
  }
  shared_vpc_service_config = (
    try(each.value.shared_vpc_service_config.host_project, null) == null
    ? null
    : merge(each.value.shared_vpc_service_config, {
      host_project = try(
        var.factories_config.context.vpc_host_projects[each.value.shared_vpc_service_config.host_project],
        module.projects[each.value.shared_vpc_service_config.host_project].project_id,
        each.value.shared_vpc_service_config.host_project
      )
      network_users = [
        for vv in try(each.value.shared_vpc_service_config.network_users, []) :
        try(
          # project service accounts (sa)
          module.service-accounts["${each.key}/${vv}"].iam_email,
          # automation service account (rw)
          local.context.iam_principals["${each.key}/automation/${vv}"],
          # automation service account (automation/rw)
          local.context.iam_principals["${each.key}/${vv}"],
          # other projects service accounts (project/sa)
          module.service-accounts[vv].iam_email,
          # other automation service account (project/automation/rw)
          local.context.iam_principals[vv],
          # passthrough + error handling using tonumber until Terraform gets fail/raise function
          (
            strcontains(vv, ":")
            ? vv
            : tonumber("[Error] Invalid member: '${vv}' in project '${each.key}'")
          )
        )
      ]
    })
  )
  # add service agents config, so Service Agents can be referred in the IAM grants
  service_agents_config = {
    # default roles are granted in module.project
    grant_default_roles = false
  }
}

module "buckets" {
  source = "../gcs"
  for_each = {
    for k in local.buckets : "${k.project_key}/${k.name}" => k
  }
  project_id     = module.projects[each.value.project_key].project_id
  prefix         = each.value.prefix
  name           = "${each.value.project_name}-${each.value.name}"
  encryption_key = each.value.encryption_key
  iam = {
    for k, v in each.value.iam : k => [
      for vv in v : try(
        # project service accounts (sa)
        module.service-accounts["${each.value.project_key}/${vv}"].iam_email,
        # automation service account (rw)
        local.context.iam_principals["${each.value.project_key}/automation/${vv}"],
        # automation service account (automation/rw)
        local.context.iam_principals["${each.value.project_key}/${vv}"],
        # other projects service accounts (project/sa)
        module.service-accounts[vv].iam_email,
        # other automation service account (project/automation/rw)
        local.context.iam_principals[vv],
        # passthrough + error handling using tonumber until Terraform gets fail/raise function
        (
          strcontains(vv, ":")
          ? vv
          : tonumber("[Error] Invalid member: '${vv}' in project '${each.value.project_key}'")
        )
      )
    ]
  }
  iam_bindings = {
    for k, v in each.value.iam_bindings : k => merge(v, {
      members = [
        for vv in v.members : try(
          # project service accounts (sa)
          module.service-accounts["${each.value.project}/${vv}"].iam_email,
          # automation service account (rw)
          local.context.iam_principals["${each.value.project}/automation/${vv}"],
          # automation service account (automation/rw)
          local.context.iam_principals["${each.value.project}/${vv}"],
          # other projects service accounts (project/sa)
          module.service-accounts[vv].iam_email,
          # other automation service account (project/automation/rw)
          local.context.iam_principals[vv],
          # passthrough + error handling using tonumber until Terraform gets fail/raise function
          (
            strcontains(vv, ":")
            ? vv
            : tonumber("[Error] Invalid member: '${vv}' in project '${each.value.project}'")
          )
        )
      ]
    })
  }
  iam_bindings_additive = {
    for k, v in each.value.iam_bindings_additive : k => merge(v, {
      member = try(
        # project service accounts (sa)
        module.service-accounts["${each.value.project}/${v.member}"].iam_email,
        # automation service account (rw)
        local.context.iam_principals["${each.value.project}/automation/${v.member}"],
        # automation service account (automation/rw)
        local.context.iam_principals["${each.value.project}/${v.member}"],
        # other projects service accounts (project/sa)
        module.service-accounts[v.member].iam_email,
        # other automation service account (project/automation/rw)
        local.context.iam_principals[v.member],
        # passthrough + error handling using tonumber until Terraform gets fail/raise function
        (
          strcontains(v.member, ":")
          ? v.member
          : tonumber("[Error] Invalid member: '${v.member}' in project '${each.value.project}'")
        )
      )
    })
  }
  labels = each.value.labels
  location = coalesce(
    var.data_overrides.storage_location,
    lookup(each.value, "location", null),
    var.data_defaults.storage_location
  )
  storage_class               = each.value.storage_class
  uniform_bucket_level_access = each.value.uniform_bucket_level_access
  versioning                  = each.value.versioning
}

module "service-accounts" {
  source = "../iam-service-account"
  for_each = {
    for k in local.service_accounts : "${k.project_key}/${k.name}" => k
  }
  project_id   = module.projects[each.value.project_key].project_id
  name         = each.value.name
  display_name = each.value.display_name
  iam = {
    for k, v in lookup(each.value, "iam", {}) : k => [
      for vv in v : try(
        # automation service account (rw)
        local.context.iam_principals["${each.key}/automation/${vv}"],
        # automation service account (automation/rw)
        local.context.iam_principals["${each.key}/${vv}"],
        # other automation service account (project/automation/rw)
        local.context.iam_principals[vv],
        # passthrough + error handling using tonumber until Terraform gets fail/raise function
        (
          strcontains(vv, ":")
          ? vv
          : tonumber("[Error] Invalid member: '${vv}' in project '${each.key}'")
        )
      )
    ]
  }
  iam_project_roles = merge(
    {
      for k, v in each.value.iam_project_roles :
      lookup(var.factories_config.context.vpc_host_projects, k, k) => v
    },
    each.value.iam_self_roles == null ? {} : {
      (module.projects[each.value.project_key].project_id) = each.value.iam_self_roles
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
