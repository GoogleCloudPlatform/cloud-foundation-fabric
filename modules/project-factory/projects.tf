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

# TODO: add project sa to context

locals {
  # project data from folders tree
  _folder_projects_raw = {
    for f in try(fileset(local._folders_path, "**/*.yaml"), []) :
    trimsuffix(f, ".yaml") => merge(
      { parent = dirname(f) == "." ? null : "$folder_ids:${dirname(f)}" },
      yamldecode(file("${local._folders_path}/${f}"))
    ) if !endswith(f, "/.config.yaml")
  }
  _projects_input = {
    for k, v in merge(local._folder_projects_raw, local._projects_raw) :
    basename(k) => merge(
      try(local._templates_raw[v.project_template], {}), v
    )
  }
  _projects_path = try(
    pathexpand(var.factories_config.projects), null
  )
  _projects_raw = {
    for f in try(fileset(local._projects_path, "**/*.yaml"), []) :
    trimsuffix(f, ".yaml") => yamldecode(file("${local._projects_path}/${f}"))
  }
  _templates_path = try(
    pathexpand(var.factories_config.project_templates), null
  )
  _templates_raw = {
    for f in try(fileset(local._templates_path, "**/*.yaml"), []) :
    trimsuffix(f, ".yaml") => yamldecode(file("${local._templates_path}/${f}"))
  }
  ctx_project_ids = merge(local.ctx.project_ids, local.project_ids)
  project_ids = {
    for k, v in module.projects : k => v.project_id
  }
  projects_input = merge(var.projects, local._projects_output)
}

module "projects" {
  source              = "../project"
  for_each            = local.projects_input
  billing_account     = each.value.billing_account
  deletion_policy     = each.value.deletion_policy
  name                = each.value.name
  parent              = each.value.parent
  prefix              = each.value.prefix
  project_reuse       = each.value.project_reuse
  alerts              = try(each.value.alerts, null)
  auto_create_network = try(each.value.auto_create_network, false)
  compute_metadata    = try(each.value.compute_metadata, {})
  # TODO: concat lists for each key
  contacts = merge(
    each.value.contacts, var.data_merges.contacts
  )
  context = merge(local.ctx, {
    folder_ids = local.ctx_folder_ids
  })
  default_service_account = try(each.value.default_service_account, "keep")
  descriptive_name        = try(each.value.descriptive_name, null)
  factories_config = {
    custom_roles  = each.value.factories_config.custom_roles
    observability = each.value.factories_config.observability
    org_policies  = each.value.factories_config.org_policies
    quotas        = each.value.factories_config.quotas
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
  services = distinct(concat(
    each.value.services,
    var.data_merges.services
  ))
  tag_bindings = merge(
    each.value.tag_bindings, var.data_merges.tag_bindings
  )
  tags     = each.value.tags
  universe = each.value.universe
  vpc_sc   = each.value.vpc_sc
  quotas   = each.value.quotas
}

module "projects-iam" {
  source   = "../project"
  for_each = local.projects_input
  name     = module.projects[each.key].project_id
  project_reuse = {
    use_data_source = false
    attributes = {
      name             = module.projects[each.key].name
      number           = module.projects[each.key].number
      services_enabled = module.projects[each.key].services
    }
  }
  context = merge(local.ctx, {
    folder_ids     = local.ctx.folder_ids
    kms_keys       = local.ctx.kms_keys
    iam_principals = local.ctx_iam_principals
  })
  iam                   = lookup(each.value, "iam", {})
  iam_bindings          = lookup(each.value, "iam_bindings", {})
  iam_bindings_additive = lookup(each.value, "iam_bindings_additive", {})
  iam_by_principals     = lookup(each.value, "iam_by_principals", {})
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
  universe                  = each.value.universe
}
