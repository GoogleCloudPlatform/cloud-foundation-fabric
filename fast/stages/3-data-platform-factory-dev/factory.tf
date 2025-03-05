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
  _dd_path = try(pathexpand(var.factories_config.data_domains), null)
  _dd_raw = {
    for f in try(fileset(local._dd_path, "**/_config.yaml"), []) :
    dirname(f) => yamldecode(file("${local._dd_path}/${f}"))
  }
  _dp = flatten([
    for k, v in local.data_domains : [
      for f in try(fileset("${local._dd_path}/${k}", "**/*.yaml"), []) : merge(
        yamldecode(file("${local._dd_path}/${k}/${f}")),
        {
          dd  = k
          dds = v.short_name
          key = trimsuffix(basename(f), ".yaml")
        }
      ) if !endswith(f, "_config.yaml")
    ]
  ])
  data_products = {
    for v in local._dp : "${v.dd}/${v.key}" => merge(v, {
      # short_name = lookup(v, "short_name", v.key)
      # services = distinct(concat(
      #   lookup(v, "services", []),
      #     try(v.exposed_resources.storage_buckets, null) == null ? [] : [
      #     "storage.googleapis.com"
      #   ],
      #     try(v.exposed_resources.bigquery_datasets, null) == null ? [] : [
      #     "bigquery.googleapis.com"
      #   ]
      # ))
      exposed_buckets  = try(v.exposed_resources.storage_buckets, {})
      exposed_datasets = try(v.exposed_resources.bigquery_datasets, {})
      # iam                   = lookup(v, "iam", {})
      # iam_bindings          = lookup(v, "iam_bindings", {})
      # iam_bindings_additive = lookup(v, "iam_bindings_additive", {})
      # iam_by_principals     = lookup(v, "iam_by_principals", {})
      # service_accounts      = lookup(v, "service_accounts", {})
      # shared_vpc_service_config = try(
      #   v.shared_vpc_service_config, null
      # )
    })
  }
  dp_datasets = flatten([
    for k, v in local.data_products : [
      for dk, dv in v.exposed_datasets : {
        dp         = k
        dps        = replace("${v.dds}-${v.short_name}", "-", "_")
        key        = dk
        short_name = replace(lookup(dv, "short_name", dk), "-", "_")
        location   = lookup(dv, "location", var.location)
      }
    ]
  ])
}
