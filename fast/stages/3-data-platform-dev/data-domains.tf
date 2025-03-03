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

module "dd-folders" {
  source                = "../../../modules/folder"
  for_each              = local.data_domains
  parent                = var.folder_ids[var.config.name]
  name                  = each.value.name
  iam                   = each.value.folder_config.iam
  iam_bindings          = each.value.folder_config.iam_bindings
  iam_bindings_additive = each.value.folder_config.iam_bindings_additive
  iam_by_principals     = each.value.folder_config.iam_by_principals
}

module "dd-projects" {
  source                = "../../../modules/project"
  for_each              = local.data_domains
  billing_account       = var.billing_account.id
  name                  = "${each.value.short_name}-shared-0"
  parent                = module.dd-folders[each.key].id
  prefix                = local.prefix
  iam                   = each.value.project_config.iam
  iam_bindings          = each.value.project_config.iam_bindings
  iam_bindings_additive = each.value.project_config.iam_bindings_additive
  iam_by_principals     = each.value.project_config.iam_by_principals
  labels = {
    data_domain = each.key
  }
  services                  = each.value.project_config.services
  shared_vpc_service_config = each.value.project_config.shared_vpc_service_config
}

module "dd-service-accounts" {
  source                = "../../../modules/iam-service-account"
  for_each              = { for v in local.dd_service_accounts : v.key => v }
  project_id            = module.dp-projects[each.value.dd].project_id
  name                  = each.value.name
  description           = each.value.description
  iam                   = each.value.iam
  iam_bindings          = each.value.iam_bindings
  iam_bindings_additive = each.value.iam_bindings_additive
  iam_storage_roles     = each.value.iam_storage_roles
}
