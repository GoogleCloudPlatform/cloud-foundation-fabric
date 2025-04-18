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

resource "google_chronicle_data_access_label" "labels" {
  for_each             = coalesce(var.data_rbac_config.labels, {})
  project              = module.project.project_id
  location             = var.tenant_config.region
  instance             = var.tenant_config.customer_id
  data_access_label_id = each.value.label_id
  udm_query            = each.value.udm_query
  description          = each.value.description
}

resource "google_chronicle_data_access_scope" "example" {
  for_each             = coalesce(var.data_rbac_config.scopes, {})
  project              = module.project.project_id
  location             = var.tenant_config.region
  instance             = var.tenant_config.customer_id
  data_access_scope_id = each.value.scope_id
  description          = each.value.description
  allow_all            = length(each.value.denied_data_access_labels) != 0
  dynamic "denied_data_access_labels" {
    for_each = each.value.denied_data_access_labels
    content {
      log_type          = denied_data_access_labels.value.log_type
      data_access_label = denied_data_access_labels.value.data_access_label
      asset_namespace   = denied_data_access_labels.value.asset_namespace
      dynamic "ingestion_label" {
        for_each = coalesce(denied_data_access_labels.value.ingestion_label, {})
        content {
          ingestion_label_key   = ingestion_label.ingestion_label_key
          ingestion_label_value = ingestion_label.ingestion_label_value
        }
      }
    }
  }
  dynamic "allowed_data_access_labels" {
    for_each = each.value.allowed_data_access_labels
    content {
      log_type          = allowed_data_access_labels.value.log_type
      data_access_label = allowed_data_access_labels.value.data_access_label
      asset_namespace   = allowed_data_access_labels.value.asset_namespace
      dynamic "ingestion_label" {
        for_each = coalesce(allowed_data_access_labels.value.ingestion_label, {})
        content {
          ingestion_label_key   = ingestion_label.ingestion_label_key
          ingestion_label_value = ingestion_label.ingestion_label_value
        }
      }
    }
  }
  depends_on = [google_chronicle_data_access_label.labels]
}
