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
  data_domains = {
    for k, v in local._dd_raw : k => {
      name       = v.name
      short_name = lookup(v, "short_name", reverse(split("/", k))[0])
      folder_config = {
        iam                   = try(v.folder_config.iam, {})
        iam_bindings          = try(v.folder_config.iam_bindings, {})
        iam_bindings_additive = try(v.folder_config.iam_bindings_additive, {})
        iam_by_principals     = try(v.folder_config.iam_by_principals, {})
      }
      project_config = {
        composer_deploy       = try(v.project_config.composer_deploy, false)
        name                  = try(v.project_config.name, k)
        services              = try(v.project_config.services, [])
        iam                   = try(v.project_config.iam, {})
        iam_bindings          = try(v.project_config.iam_bindings, {})
        iam_bindings_additive = try(v.project_config.iam_bindings_additive, {})
        iam_by_principals     = try(v.project_config.iam_by_principals, {})
        shared_vpc_service_config = try(
          v.project_config.shared_vpc_service_config, null
        )
      }
      service_accounts = lookup(v, "service_accounts", {})
    }
  }
  data_products = {
    for v in local._dp : "${v.dd}/${v.key}" => merge(v, {
      dd         = v.dd
      short_name = lookup(v, "short_name", v.key)
      services = distinct(concat(
        lookup(v, "services", []),
        try(v.exposed_resources.storage_buckets, null) == null ? [] : [
          "storage.googleapis.com"
        ],
        try(v.exposed_resources.bigquery_datasets, null) == null ? [] : [
          "bigquery.googleapis.com"
        ]
      ))
      exposed_buckets       = try(v.exposed_resources.storage_buckets, {})
      exposed_datasets      = try(v.exposed_resources.bigquery_datasets, {})
      iam                   = lookup(v, "iam", {})
      iam_bindings          = lookup(v, "iam_bindings", {})
      iam_bindings_additive = lookup(v, "iam_bindings_additive", {})
      iam_by_principals     = lookup(v, "iam_by_principals", {})
      service_accounts      = lookup(v, "service_accounts", {})
      shared_vpc_service_config = try(
        v.shared_vpc_service_config, null
      )
    })
  }
  dd_service_accounts = flatten([
    for k, v in local.data_domains : [
      for sk, sv in v.service_accounts : {
        dd                    = k
        key                   = "${k}/${sk}"
        name                  = lookup(sv, "name", "${v.short_name}-${sk}")
        description           = lookup(v, "description", null)
        iam                   = lookup(sv, "iam", {})
        iam_bindings          = lookup(sv, "iam_bindings", {})
        iam_bindings_additive = lookup(sv, "iam_bindings_additive", {})
        iam_storage_roles     = lookup(sv, "iam_storage_roles", {})
      }
    ]
  ])
  dp_buckets = flatten([
    for k, v in local.data_products : [
      for bk, bv in v.exposed_buckets : {
        dp            = k
        dps           = "${v.dds}-${v.short_name}"
        key           = bk
        short_name    = lookup(bv, "short_name", bk)
        location      = lookup(bv, "location", var.location)
        storage_class = lookup(bv, "storage_class", null)
      }
    ]
  ])
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
  dp_service_accounts = flatten([
    for k, v in local.data_products : [
      for sk, sv in v.service_accounts : {
        dp  = k
        key = "${k}/${sk}"
        name = lookup(
          sv, "name", "${v.dds}-${v.short_name}-${sk}"
        )
        description           = lookup(v, "description", null)
        iam                   = lookup(sv, "iam", {})
        iam_bindings          = lookup(sv, "iam_bindings", {})
        iam_bindings_additive = lookup(sv, "iam_bindings_additive", {})
        iam_storage_roles     = lookup(sv, "iam_storage_roles", {})
      }
    ]
  ])
}
