/**
 * Copyright 2019 Google LLC
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
  datasets = {
    for id, data in var.datasets :
    id => merge(data, {
      options = lookup(var.dataset_options, id, var.default_options)
      access  = lookup(var.dataset_access, id, var.default_access)
      labels  = data.labels == null ? {} : data.labels
    })
  }
}

resource "google_bigquery_dataset" "datasets" {
  for_each      = local.datasets
  project       = var.project_id
  dataset_id    = each.key
  friendly_name = each.value.name
  description   = each.value.description
  labels        = merge(var.default_labels, each.value.labels)
  location      = each.value.location

  delete_contents_on_destroy      = each.value.options.delete_contents_on_destroy
  default_table_expiration_ms     = each.value.options.default_table_expiration_ms
  default_partition_expiration_ms = each.value.options.default_partition_expiration_ms

  dynamic access {
    for_each = each.value.access
    iterator = config
    content {
      role           = config.value.role
      domain         = each.value.identity_type == "domain" ? each.value.identity : null
      group_by_email = each.value.identity_type == "group_by_email" ? each.value.identity : null
      special_group  = each.value.identity_type == "special_group" ? each.value.identity : null
      user_by_email  = each.value.identity_type == "user_by_email" ? each.value.identity : null
      dynamic view {
        for_each = each.value.identity_type == "view" ? [""] : []
        content {
          project_id = view.value.project_id
          dataset_id = view.value.dataset_id
          table_id   = view.value.table_id
        }
      }
    }
  }

  dynamic default_encryption_configuration {
    for_each = var.kms_key == null ? [] : [""]
    content {
      kms_key_name = var.kms_key
    }
  }
}
