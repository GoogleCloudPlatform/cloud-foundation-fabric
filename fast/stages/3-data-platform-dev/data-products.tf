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

module "dp-projects" {
  source          = "../../../modules/project"
  for_each        = local.data_products
  billing_account = var.billing_account.id
  name            = "${each.value.dds}-${each.value.short_name}-0"
  parent          = module.dd-folders[each.value.dd].id
  prefix          = local.prefix
  labels = {
    data_domain  = each.value.dd
    data_product = replace(each.key, "/", "_")
  }
  services                  = each.value.services
  shared_vpc_service_config = each.value.shared_vpc_service_config
}

module "dp-projects-iam" {
  source   = "../../../modules/project"
  for_each = local.data_products
  name     = module.dp-projects[each.key].project_id
  project_reuse = {
    use_data_source = false
    project_attributes = {
      name   = module.dp-projects[each.key].name
      number = module.dp-projects[each.key].number
    }
  }
  iam = {
    for k, v in each.value.iam : k => [
      for m in v : try(
        local.service_accounts_iam[m],
        local.service_accounts_iam["${each.key}/${m}"],
        strcontains(m, ":") ? m : tonumber("[Error] Invalid member: '${m}' in project '${each.key}'")
      )
    ]
  }
  iam_bindings = {
    for k, v in each.value.iam_bindings : k => merge(v, {
      members = [
        for m in v.members : try(
          local.service_accounts_iam[m],
          local.service_accounts_iam["${each.key}/${m}"],
          strcontains(m, ":") ? m : tonumber("[Error] Invalid member: '${m}' in project '${each.key}'")
        )
      ]
    })
  }
  iam_bindings_additive = {
    for k, v in each.value.iam_bindings_additive : k => merge(v, {
      member = try(
        local.service_accounts_iam[v.member],
        local.service_accounts_iam["${each.key}/${v.member}"],
        strcontains(v.member, ":") ? v.member : tonumber("[Error] Invalid member: '${v.member}' in project '${each.key}'")
      )
    })
  }
  iam_by_principals = each.value.iam_by_principals
}

module "dp-buckets" {
  source = "../../../modules/gcs"
  for_each = {
    for v in local.dp_buckets : "${v.dp}/${v.key}" => v
  }
  project_id = module.dp-projects[each.value.dp].project_id
  prefix     = local.prefix
  name       = "${each.value.dps}-${each.value.short_name}-0"
  location   = each.value.location
  tag_bindings = {
    exposure = (
      module.central-project.tag_values["${var.exposure_config.tag_name}"].id
    )
  }
}

module "dp-datasets" {
  source = "../../../modules/bigquery-dataset"
  for_each = {
    for v in local.dp_datasets : "${v.dp}/${v.key}" => v
  }
  project_id = module.dp-projects[each.value.dp].project_id
  id         = "${local.prefix_bq}_${each.value.dps}_${each.value.short_name}_0"
  location   = each.value.location
  tag_bindings = {
    exposure = (
      module.central-project.tag_values["${var.exposure_config.tag_name}"].id
    )
  }
}

module "dp-service-accounts" {
  source                = "../../../modules/iam-service-account"
  for_each              = { for v in local.dp_service_accounts : v.key => v }
  project_id            = module.dp-projects[each.value.dp].project_id
  prefix                = local.prefix
  name                  = each.value.name
  description           = each.value.description
  iam                   = each.value.iam
  iam_bindings          = each.value.iam_bindings
  iam_bindings_additive = each.value.iam_bindings_additive
  iam_storage_roles     = each.value.iam_storage_roles
}
