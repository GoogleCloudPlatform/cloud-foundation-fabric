/**
 * Copyright 2023 Google LLC
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
  # group by dataset
  _factory_data_tables = {
    for k, v in local._factory_raw_tables : v.dataset => {
      key                 = k
      friendly_name       = v.table
      schema              = jsonencode(v.schema)
      labels              = try(v.labels, null)
      options             = try(v.options, null)
      partitioning        = try(v.partitioning, null)
      use_legacy_sql      = try(v.use_legacy_sql, false)
      deletion_protection = try(v.deletion_protection, false)
    }...
  }
  _factory_data_views = {
    for k, v in local._factory_raw_views : v.dataset => {
      key                 = k
      query               = v.query
      friendly_name       = v.view
      labels              = try(v.labels, null)
      use_legacy_sql      = try(v.use_legacy_sql, false)
      deletion_protection = try(v.deletion_protection, false)
    }...
  }
  # raw data from yaml
  _factory_raw_tables = {
    for f in fileset("${local._factory_path_tables}", "**/*.yaml") :
    trimsuffix(f, ".yaml") => yamldecode(file(
      "${local._factory_path_tables}/${f}"
    ))
  }
  _factory_raw_views = {
    for f in fileset("${local._factory_path_views}", "**/*.yaml") :
    trimsuffix(f, ".yaml") => yamldecode(file(
      "${local._factory_path_views}/${f}"
    ))
  }
  # alias paths for legibility
  _factory_path_tables = var.factory_config.bq_tables_data_path
  _factory_path_views  = var.factory_config.bq_views_data_path
  # assemble datasets
  factory_dataset_names = distinct(concat(
    keys(local._factory_data_tables),
    keys(local._factory_data_views)
  ))
  factory_datasets = {
    for k in local._factory_dataset_names : k => {
      tables = lookup(local._factory_data_tables, k, {})
      views  = lookup(local._factory_data_views, k, {})
    }
  }
}
