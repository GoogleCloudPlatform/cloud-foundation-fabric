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

# TODO: add project sa to context

locals {
  # project data from folders tree
  _folder_projects_raw = {
    for f in try(fileset(local.paths.folders, "**/*.yaml"), []) :
    trimsuffix(f, ".yaml") => merge(
      { parent = dirname(f) == "." ? null : "$folder_ids:${dirname(f)}" },
      yamldecode(file("${local.paths.folders}/${f}"))
    ) if !endswith(f, "/.config.yaml")
  }
  _projects_input = {
    for k, v in merge(local._folder_projects_raw, local._projects_raw) :
    basename(k) => merge(
      try(local._templates_raw[v.project_template], {}),
      v
    )
  }
  _projects_raw = {
    for f in try(fileset(local.paths.projects, "**/*.yaml"), []) :
    trimsuffix(f, ".yaml") => yamldecode(file("${local.paths.projects}/${f}"))
    if !endswith(f, ".config.yaml")
  }
  _templates_path = try(
    pathexpand(local.paths.project_templates), null
  )
  _templates_raw = {
    for f in try(fileset(local._templates_path, "**/*.yaml"), []) :
    trimsuffix(f, ".yaml") => yamldecode(file("${local._templates_path}/${f}"))
  }
  ctx_project_ids     = merge(local.ctx.project_ids, local.project_ids)
  ctx_project_numbers = merge(local.ctx.project_numbers, local.project_numbers)
  # cross-project tag contexts, keyed on project name
  ctx_tag_keys = merge(local.ctx.tag_keys, {
    for k, v in merge([
      for pk, pv in local.projects_input : {
        for tk, tv in module.projects[pk].tag_keys :
        "${pv.name}/${tk}" => tv.id
      }
    ]...) : k => v
  })
  ctx_tag_values = merge(local.ctx.tag_values, {
    for k, v in merge([
      for pk, pv in local.projects_input : {
        for tk, tv in module.projects[pk].tag_values :
        "${pv.name}/${tk}" => tv.id
      }
    ]...) : k => v
  })
  project_ids = {
    for k, v in module.projects : k => v.project_id
  }
  project_numbers = {
    for k, v in module.projects : k => v.number
  }
  projects_input = {
    for k, v in merge(var.projects, local._projects_output) : k => merge(v, {
      factories_config = {
        for kk, vv in v.factories_config : kk => try(pathexpand(
          var.factories_config.basepath == null || startswith(vv, "/") || startswith(vv, ".")
          ? vv :
          "${var.factories_config.basepath}/${vv}"
        ), null)
      }
    })
  }
  projects_service_agents = merge([
    for k, v in module.projects : {
      for kk, vv in v.service_agents : "service_agents/${k}/${kk}" => vv.iam_email
    }
  ]...)
}

resource "terraform_data" "project-preconditions" {
  lifecycle {
    precondition {
      condition = alltrue([
        for k, v in local._projects_input :
        try(v.project_template, null) == null ||
        lookup(local._templates_raw, v.project_template, null) != null
      ])
      error_message = "Missing project templates referenced in projects."
    }
  }
}

module "projects" {
  source              = "../project"
  for_each            = local.projects_input
  billing_account     = each.value.billing_account
  deletion_policy     = each.value.deletion_policy
  name                = each.value.name
  descriptive_name    = each.value.descriptive_name
  parent              = each.value.parent
  prefix              = each.value.prefix
  project_reuse       = each.value.project_reuse
  alerts              = try(each.value.alerts, null)
  asset_feeds         = each.value.asset_feeds
  auto_create_network = try(each.value.auto_create_network, false)
  compute_metadata    = try(each.value.compute_metadata, {})
  # TODO: concat lists for each key
  contacts = merge(
    each.value.contacts, var.data_merges.contacts
  )
  context = merge(local.ctx, {
    condition_vars = merge(local.ctx.condition_vars, {
      folder_ids = {
        for k, v in local.ctx_folder_ids : replace(k, "$folder_ids:", "") => v
      }
    })
    folder_ids = local.ctx_folder_ids
  })
  default_service_account = try(each.value.default_service_account, "keep")
  # postpone factories that might leverage context
  factories_config = {
    for k, v in each.value.factories_config :
    k => v if !contains(["aspect_types", "pam_entitlements"], k)
  }
  kms_autokeys = try(each.value.kms.autokeys, {})
  labels = merge(
    each.value.labels, var.data_merges.labels
  )
  lien_reason        = try(each.value.lien_reason, null)
  log_scopes         = try(each.value.log_scopes, null)
  logging_exclusions = try(each.value.logging_exclusions, {})
  logging_metrics    = try(each.value.logging_metrics, null)
  logging_sinks      = try(each.value.logging_sinks, {})
  metric_scopes = distinct(concat(
    each.value.metric_scopes, var.data_merges.metric_scopes
  ))
  notification_channels = try(each.value.notification_channels, null)
  org_policies          = each.value.org_policies
  quotas                = each.value.quotas
  services = distinct(concat(
    each.value.services,
    var.data_merges.services
  ))
  tags = each.value.tags
  tags_config = {
    ignore_iam = true
  }
  universe                = each.value.universe
  vpc_sc                  = each.value.vpc_sc
  workload_identity_pools = each.value.workload_identity_pools
}

module "projects-iam" {
  source   = "../project"
  for_each = local.projects_input
  name     = each.value.name
  prefix   = each.value.prefix
  project_reuse = {
    use_data_source = false
    attributes = {
      name             = module.projects[each.key].name
      number           = module.projects[each.key].number
      services_enabled = module.projects[each.key].services
    }
  }
  context = merge(local.ctx, {
    folder_ids = local.ctx.folder_ids
    kms_keys   = merge(local.ctx.kms_keys, local.kms_keys)
    iam_principals = merge(
      local.ctx_iam_principals,
      lookup(local.self_sas_iam_emails, each.key, {}),
      local.projects_service_agents
    )
    project_ids = merge(
      local.ctx.project_ids,
      { for k, v in module.projects : k => v.project_id }
    )
    tag_keys   = local.ctx_tag_keys
    tag_values = local.ctx_tag_values
  })
  factories_config = {
    # we do anything that can refer to IAM and custom roles in this call
    aspect_types     = each.value.factories_config.aspect_types
    pam_entitlements = each.value.factories_config.pam_entitlements
  }
  iam                           = lookup(each.value, "iam", {})
  iam_bindings                  = lookup(each.value, "iam_bindings", {})
  iam_bindings_additive         = lookup(each.value, "iam_bindings_additive", {})
  iam_by_principals             = lookup(each.value, "iam_by_principals", {})
  iam_by_principals_conditional = lookup(each.value, "iam_by_principals_conditional", {})
  iam_by_principals_additive    = lookup(each.value, "iam_by_principals_additive", {})
  logging_data_access           = lookup(each.value, "logging_data_access", {})
  pam_entitlements              = try(each.value.pam_entitlements, {})
  service_agents_config = {
    create_primary_agents = false
    grant_default_roles   = false
  }
  service_encryption_key_ids = merge(
    each.value.service_encryption_key_ids,
    var.data_merges.service_encryption_key_ids
  )
  shared_vpc_host_config    = each.value.shared_vpc_host_config
  shared_vpc_service_config = each.value.shared_vpc_service_config
  tag_bindings = merge(
    each.value.tag_bindings, var.data_merges.tag_bindings
  )
  tags = each.value.tags
  tags_config = {
    force_context_ids = true
  }
  universe = each.value.universe
  # we use explicit depends_on as this allows us passing name and prefix
  depends_on = [
    module.projects
  ]
}
