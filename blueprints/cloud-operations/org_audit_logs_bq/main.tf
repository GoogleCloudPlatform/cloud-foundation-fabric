/**
 * Copyright 2022 Google LLC
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

module "project" {
  source = "../../../modules/project"
  billing_account = (var.project_create != null
    ? var.project_create.billing_account_id
    : null
  )
  parent = (var.project_create != null
    ? var.project_create.parent
  : null)
  prefix = (var.project_create == null
    ? null
  : var.prefix)
  name = var.project_id
  services = [
    "logging.googleapis.com",
    "bigquery.googleapis.com"
  ]
  service_config = {
    disable_on_destroy         = false
    disable_dependent_services = false
  }
  project_create = var.project_create != null
}

resource "google_logging_organization_sink" "audit_log_org_sink" {
  name             = "audit-log-org-sink"
  org_id           = var.org_id
  include_children = true
  destination      = "bigquery.googleapis.com/projects/${module.project.project_id}/datasets/${module.bigquery-dataset.dataset_id}"
  filter           = var.filter
  dynamic "exclusions" {
    for_each = var.exclusions
    iterator = exclusion
    content {
      name   = exclusion.key
      filter = exclusion.value
    }
  }
  bigquery_options {
    use_partitioned_tables = true
  }
}

resource "google_project_iam_member" "org_sa_bq_role" {
  project = module.project.project_id
  role    = "roles/bigquery.dataEditor"
  member  = google_logging_organization_sink.audit_log_org_sink.writer_identity
}

module "bigquery-dataset" {
  source     = "../../../modules/bigquery-dataset"
  project_id = module.project.project_id
  id         = var.dataset_id
  location   = var.location
  options = {
    default_table_expiration_ms     = null
    default_partition_expiration_ms = null
    delete_contents_on_destroy      = true
  }
}
