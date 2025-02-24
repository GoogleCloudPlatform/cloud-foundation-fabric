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

/* locals {
  _data_products = flatten([
    for k, v in local.data_domains : [
      for pk, pv in v.data_products : merge(pv, {
        data_domain = k
        key         = "${k}-${pk}"
        name        = pk
        short_name  = "${v.short_name}-${coalesce(v.short_name, pk)}"
      })
    ]
  ])
  _dp_bqds = flatten([
    for k, v in local.data_products : [
      for bk, bv in pv.exposed_resources.bigquery : merge(bv, {
        data_product     = k
        data_product_key = v.key
        key              = "${v.key}-${bk}"
        location         = coalesce(v.location, local.default_location)
        name             = bk
        short_name       = replace("${v.short_name}_${bk}", "-", "_")
      })
    ]
  ])
  _dp_buckets = flatten([
    for k, v in local.data_products : [
      for bk, bv in pv.exposed_resources.gcs : merge(bv, {
        data_product     = k
        data_product_key = v.key
        key              = "${v.key}-${bk}"
        location         = coalesce(v.location, local.default_location)
        name             = bk
        short_name       = "${v.short_name}-${bk}"
      })
    ]
  ])
  data_domains = {
    for k, v in var.data_domains : k => merge(v, {
      short_name = coalesce(v.short_name, k)
    })
  }
  data_products = {
    for v in local._data_products : v.key => v
  }
  dp_bqds = {
    for v in local._dp_bqds : v.key => v
  }
  dp_buckets = {
    for v in local._dp_buckets : v.key => v
  }
}

module "dd-folder" {
  source                = "../../../modules/folder"
  for_each              = local.data_domains
  parent                = var.folder_ids[var.stage_config.name]
  name                  = each.value.folder_config.name
  iam                   = each.value.iam
  iam_bindings          = each.value.iam_bindings
  iam_bindings_additive = each.value.iam_bindings_additive
  iam_by_principals     = each.value.iam_by_principals
}

module "dd-project" {
  source                = "../../../modules/project"
  for_each              = local.data_domains
  billing_account       = var.billing_account.id
  name                  = "dp-${each.value.short_name}-central-0"
  parent                = module.dd-folder[each.key].id
  prefix                = var.prefix
  iam                   = each.value.iam
  iam_bindings          = each.value.iam_bindings
  iam_bindings_additive = each.value.iam_bindings_additive
  iam_by_principals     = each.value.iam_by_principals
  labels = {
    data_domain = each.key
  }
  services = each.value.services
}

module "dp-project" {
  source                = "../../../modules/project"
  for_each              = local.data_products
  billing_account       = var.billing_account.id
  name                  = "dp-${each.value.short_name}-0"
  parent                = module.dd-folder[each.value.dd].id
  prefix                = var.prefix
  iam                   = each.value.iam
  iam_bindings          = each.value.iam_bindings
  iam_bindings_additive = each.value.iam_bindings_additive
  iam_by_principals     = each.value.iam_by_principals
  labels = {
    data_domain  = each.value.dd
    data_product = each.key
  }
  services = each.value.services
}

module "dp-bucket" {
  source     = "../../../modules/gcs"
  for_each   = local.dp_buckets
  project_id = module.dp_project[each.value.data_product_key].project_id
  prefix     = var.prefix
  name       = "dp-${each.value.short_name}-0"
  location   = each.value.location
  tag_bindings = {
    exposure = (
      module.central_project.tag_values["${var.data_exposure_config.tag_name}"]
    )
  }
}

module "bigquery-dataset" {
  source     = "../../../modules/bigquery-dataset"
  project_id = module.dp_project[each.value.data_product_key].project_id
  id         = "dp_${each.value.short_name}_0"
  location   = each.value.location
  tag_bindings = {
    exposure = (
      module.central_project.tag_values["${var.data_exposure_config.tag_name}"]
    )
  }
}
 */
