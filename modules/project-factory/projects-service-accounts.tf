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

locals {
  projects_service_accounts = flatten([
    for k, project in local.projects_input : [
      for name, opts in lookup(project, "service_accounts", {}) : {
        project_key = k
        name        = name
        description = try(opts.description, null)
        display_name = coalesce(
          try(local.data_defaults.overrides.service_accounts.display_name, null),
          try(opts.display_name, null),
          try(local.data_defaults.defaults.service_accounts.display_name, null),
          "Terraform-managed."
        )
        iam                    = try(opts.iam, {})
        iam_bindings           = try(opts.iam_bindings, {})
        iam_bindings_additive  = try(opts.iam_bindings_additive, {})
        iam_billing_roles      = try(opts.iam_billing_roles, {})
        iam_organization_roles = try(opts.iam_organization_roles, {})
        iam_sa_roles           = try(opts.iam_sa_roles, {})
        iam_project_roles      = try(opts.iam_project_roles, {})
        iam_self_roles = distinct(concat(
          try(local.data_defaults.overrides.service_accounts.iam_self_roles, []),
          try(opts.iam_self_roles, []),
          try(local.data_defaults.defaults.service_accounts.iam_self_roles, []),
        ))
        iam_storage_roles = try(opts.iam_storage_roles, {})
        tag_bindings      = try(opts.tag_bindings, {})
        opts              = opts
      }
    ]
  ])
  projects_sas_iam_emails = {
    for k, v in module.service-accounts : "service_accounts/${k}" => v.iam_email
  }
  projects_sas_ids = merge(
    {
      for k, v in module.service-accounts : k => v.id
    },
    {
      for k, v in module.automation-service-accounts : k => v.id
    }
  )
  self_sas = {
    for k in local.projects_service_accounts :
    k.project_key => { key = "${k.project_key}/${k.name}", name = k.name }...
  }
  self_sas_iam_emails = {
    for k, v in local.self_sas : k => {
      for vv in v :
      "service_accounts/_self_/${vv.name}" => module.service-accounts[vv.key].iam_email
    }
  }
  self_sas_ids = {
    for k, v in local.self_sas : k => {
      for vv in v :
      "_self_/${vv.name}" => module.service-accounts[vv.key].id
    }
  }
}

module "service-accounts" {
  source = "../iam-service-account"
  for_each = {
    for k in local.projects_service_accounts :
    "${k.project_key}/${k.name}" => k
  }
  project_id   = module.projects[each.value.project_key].project_id
  name         = each.value.name
  description  = each.value.description
  display_name = each.value.display_name
  context = merge(local.ctx, {
    project_ids = local.ctx_project_ids
    tag_values  = local.ctx_tag_values
  })
  iam_project_roles = merge(
    each.value.iam_project_roles,
    {
      "$project_ids:${each.value.project_key}" = each.value.iam_self_roles
    }
  )
  tag_bindings = each.value.tag_bindings
}

module "service_accounts-iam" {
  source = "../iam-service-account"
  for_each = {
    for k in local.projects_service_accounts :
    "${k.project_key}/${k.name}" => k
    if k.iam_sa_roles != {} || k.iam != {}
  }
  project_id = (
    module.service-accounts[each.key].service_account.project
  )
  name = each.value.name
  service_account_reuse = {
    use_data_source = false
  }
  context = merge(local.ctx, {
    project_ids = local.ctx_project_ids
    iam_principals = merge(
      local.ctx.iam_principals,
      local.projects_sas_iam_emails,
      local.automation_sas_iam_emails,
      lookup(local.self_sas_iam_emails, each.value.project_key, {})
    )
    service_account_ids = merge(
      local.projects_sas_ids,
      lookup(local.self_sas_ids, each.value.project_key, {})
    )
  })
  iam                   = each.value.iam
  iam_bindings          = each.value.iam_bindings
  iam_bindings_additive = each.value.iam_bindings_additive
  iam_sa_roles          = each.value.iam_sa_roles
}
