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

# tfdoc:file:description Data product exposure layer resources.

module "dp-buckets" {
  source = "../../../modules/gcs"
  for_each = {
    for v in local.dp_buckets : "${v.dp}/${v.key}" => v
  }
  project_id = module.dp-projects[each.value.dp].project_id
  prefix     = local.prefix
  name       = "${each.value.dps}-${each.value.short_name}-0"
  location   = each.value.location
  encryption_key = (
    local.dp_bucket_keys[each.key] == null
    ? null
    : lookup(
      local.kms_keys,
      local.dp_bucket_keys[each.key],
      local.dp_bucket_keys[each.key]
    )
  )
  iam = {
    for k, v in each.value.iam : k => [
      for m in v : try(
        var.factories_config.context.iam_principals[m],
        module.dp-automation-sa["${each.key}/${m}"].iam_email,
        module.dp-service-accounts["${each.key}/${m}"].iam_email,
        m
      )
    ]
  }
  tag_bindings = {
    exposure = (
      module.central-project.tag_values[var.exposure_config.tag_name].id
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
  encryption_key = (
    local.dp_dataset_keys[each.key] == null
    ? null
    : lookup(
      local.kms_keys,
      local.dp_dataset_keys[each.key],
      local.dp_dataset_keys[each.key]
    )
  )
  iam = {
    for k, v in each.value.iam : k => [
      for m in v : try(
        var.factories_config.context.iam_principals[m],
        module.dp-automation-sa["${each.key}/${m}"].iam_email,
        module.dp-service-accounts["${each.key}/${m}"].iam_email,
        m
      )
    ]
  }
  tag_bindings = {
    exposure = (
      module.central-project.tag_values[var.exposure_config.tag_name].id
    )
  }
}
