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

# tfdoc:file:description Phase 1: Service accounts (create + IAM split).

locals {
  _service_accounts_raw = {
    for f in try(fileset(local.paths.service_accounts, "*.yaml"), []) :
    trimsuffix(f, ".yaml") => yamldecode(
      file("${local.paths.service_accounts}/${f}")
    )
  }
  # service accounts which need a second pass for IAM on themselves
  _service_accounts_iam = {
    for k, v in local._service_accounts_raw : k => v
    if length(merge(
      try(v.iam, {}),
      try(v.iam_bindings, {}),
      try(v.iam_bindings_additive, {}),
      try(v.iam_by_principals, {}),
      try(v.iam_by_principals_additive, {}),
      try(v.iam_sa_bindings, {}),
      try(v.iam_sa_roles, {})
    )) > 0
  }
}

module "service-accounts" {
  source                       = "../iam-service-account"
  for_each                     = local._service_accounts_raw
  project_id                   = try(each.value.project_id, null)
  name                         = try(each.value.name, each.key)
  prefix                       = try(each.value.prefix, null)
  description                  = try(each.value.description, null)
  display_name                 = try(each.value.display_name, "Terraform-managed.")
  create_ignore_already_exists = try(each.value.create_ignore_already_exists, null)
  deletion_policy              = try(each.value.deletion_policy, null)
  context                      = local.ctx
  iam_billing_bindings         = try(each.value.iam_billing_bindings, {})
  iam_billing_roles            = try(each.value.iam_billing_roles, {})
  iam_folder_bindings          = try(each.value.iam_folder_bindings, {})
  iam_folder_roles             = try(each.value.iam_folder_roles, {})
  iam_organization_bindings    = try(each.value.iam_organization_bindings, {})
  iam_organization_roles       = try(each.value.iam_organization_roles, {})
  iam_project_bindings         = try(each.value.iam_project_bindings, {})
  iam_project_roles            = try(each.value.iam_project_roles, {})
  iam_storage_bindings         = try(each.value.iam_storage_bindings, {})
  iam_storage_roles            = try(each.value.iam_storage_roles, {})
  tag_bindings                 = try(each.value.tag_bindings, {})
}

module "service-accounts-iam" {
  source     = "../iam-service-account"
  for_each   = local._service_accounts_iam
  project_id = module.service-accounts[each.key].service_account.project
  name       = try(each.value.name, each.key)
  prefix     = try(each.value.prefix, null)
  service_account_reuse = {
    use_data_source = false
  }
  context = merge(local.ctx, {
    iam_principals      = local.ctx_iam_principals
    service_account_ids = local.ctx_service_account_ids
  })
  iam                        = try(each.value.iam, {})
  iam_bindings               = try(each.value.iam_bindings, {})
  iam_bindings_additive      = try(each.value.iam_bindings_additive, {})
  iam_by_principals          = try(each.value.iam_by_principals, {})
  iam_by_principals_additive = try(each.value.iam_by_principals_additive, {})
  iam_sa_bindings            = try(each.value.iam_sa_bindings, {})
  iam_sa_roles               = try(each.value.iam_sa_roles, {})
}
