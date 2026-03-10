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
}

module "service-accounts" {
  source   = "../iam-service-account"
  for_each = local._service_accounts_raw
  project_id   = try(each.value.project_id, null)
  name         = try(each.value.name, each.key)
  description  = try(each.value.description, null)
  display_name = try(each.value.display_name, "Terraform-managed.")
  prefix       = try(each.value.prefix, null)
  context = merge(local.ctx, {
    iam_principals = local.ctx_iam_principals
  })
  iam_billing_roles      = try(each.value.iam_billing_roles, {})
  iam_folder_roles       = try(each.value.iam_folder_roles, {})
  iam_organization_roles = try(each.value.iam_organization_roles, {})
  iam_project_roles      = try(each.value.iam_project_roles, {})
  iam_storage_roles      = try(each.value.iam_storage_roles, {})
  tag_bindings           = try(each.value.tag_bindings, {})
}

module "service-accounts-iam" {
  source   = "../iam-service-account"
  for_each = {
    for k, v in local._service_accounts_raw : k => v
    if try(v.iam, null) != null || try(v.iam_sa_roles, null) != null
  }
  project_id = module.service-accounts[each.key].service_account.project
  name       = try(each.value.name, each.key)
  service_account_reuse = {
    use_data_source = false
  }
  context = merge(local.ctx, {
    iam_principals = local.ctx_iam_principals
  })
  iam                   = try(each.value.iam, {})
  iam_bindings          = try(each.value.iam_bindings, {})
  iam_bindings_additive = try(each.value.iam_bindings_additive, {})
  iam_by_principals     = try(each.value.iam_by_principals, {})
  iam_sa_roles          = try(each.value.iam_sa_roles, {})
}
