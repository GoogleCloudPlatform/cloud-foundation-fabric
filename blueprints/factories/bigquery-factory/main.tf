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
  views = {
    for f in fileset(var.views_path, "**/*.yaml") :
    trimsuffix(f, ".yaml") => yamldecode(file("${var.views_path}/${f}"))
  }

  tables = {
    for f in fileset(var.tables_path, "**/*.yaml") :
    trimsuffix(f, ".yaml") => yamldecode(file("${var.tables_path}/${f}"))
  }

  all_datasets = distinct(concat(
    [for x in values(local.tables) : x.dataset],
    [for x in values(local.views) : x.dataset]
  ))

  datasets = {
    for dataset in local.all_datasets :
    dataset => {
      "views" = {
        for k, v in local.views :
        v.view => {
          friendly_name       = v.view
          labels              = try(v.labels, null)
          query               = v.query
          use_legacy_sql      = try(v.use_legacy_sql, false)
          deletion_protection = try(v.deletion_protection, false)
        }
        if v.dataset == dataset
      },
      "tables" = {
        for k, v in local.tables :
        v.table => {
          friendly_name       = v.table
          labels              = try(v.labels, null)
          options             = try(v.options, null)
          partitioning        = try(v.partitioning, null)
          schema              = jsonencode(v.schema)
          use_legacy_sql      = try(v.use_legacy_sql, false)
          deletion_protection = try(v.deletion_protection, false)
        }
        if v.dataset == dataset
      }
    }
  }
}

module "bq" {
  source     = "../../../modules/bigquery-dataset"
  for_each   = local.datasets
  project_id = var.project_id
  id         = each.key
  views      = try(each.value.views, null)
  tables     = try(each.value.tables, null)
}
