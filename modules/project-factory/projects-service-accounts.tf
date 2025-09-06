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
        display_name = coalesce(
          try(local.data_defaults.overrides.service_accounts.display_name, null),
          try(opts.display_name, null),
          try(local.data_defaults.defaults.service_accounts.display_name, null),
          "Terraform-managed."
        )
        iam                    = try(opts.iam, {})
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
        opts              = opts
      }
    ]
  ])
  projects_sas_iam_emails = {
    for k, v in module.service-accounts : "service_accounts/${k}" => v.iam_email
  }
  project_sas_ids = merge(
    {
      for k, v in module.service-accounts : k => v.id
    },
    {
      for k, v in module.automation-service-accounts : k => v.id
    }
  )
}

module "service-accounts" {
  source = "../iam-service-account"
  for_each = {
    for k in local.projects_service_accounts :
    "${k.project_key}/${k.name}" => k
  }
  project_id   = module.projects[each.value.project_key].project_id
  name         = each.value.name
  display_name = each.value.display_name
  context = merge(local.ctx, {
    project_ids = local.ctx_project_ids
  })
  iam_project_roles = merge(
    each.value.iam_project_roles,
    {
      "$project_ids:${each.value.project_key}" = each.value.iam_self_roles
    }
  )
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
  name                   = each.value.name
  service_account_create = false
  context = merge(local.ctx, {
    project_ids = local.ctx_project_ids
    iam_principals = merge(
      local.ctx.iam_principals,
      local.projects_sas_iam_emails,
      local.automation_sas_iam_emails
    )
    service_account_ids = local.project_sas_ids
  })
  iam          = each.value.iam
  iam_sa_roles = each.value.iam_sa_roles
}
