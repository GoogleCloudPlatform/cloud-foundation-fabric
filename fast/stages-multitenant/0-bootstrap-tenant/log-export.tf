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

# tfdoc:file:description Audit log project and sink.

locals {
  log_sink_destinations = merge(
    # use the same dataset for all sinks with `bigquery` as  destination
    { for k, v in var.log_sinks : k => module.log-export-dataset.0 if v.type == "bigquery" },
    # use the same gcs bucket for all sinks with `storage` as destination
    { for k, v in var.log_sinks : k => module.log-export-gcs.0 if v.type == "storage" },
    # use separate pubsub topics and logging buckets for sinks with
    # destination `pubsub` and `logging`
    module.log-export-pubsub,
    module.log-export-logbucket
  )
  log_types = toset([for k, v in var.log_sinks : v.type])
}

module "log-export-project" {
  source          = "../../../modules/project"
  billing_account = var.billing_account.id
  name            = "audit-logs-0"
  parent = coalesce(
    var.project_parent_ids.logging,
    module.tenant-folder.id
  )
  prefix = local.prefix
  iam = {
    "roles/owner" = [
      module.automation-tf-resman-sa.iam_email,
      "serviceAccount:${local.resman_sa}"
    ]
  }
  services = [
    # "cloudresourcemanager.googleapis.com",
    # "iam.googleapis.com",
    # "serviceusage.googleapis.com",
    "bigquery.googleapis.com",
    "storage.googleapis.com",
    "stackdriver.googleapis.com"
  ]
}

# one log export per type, with conditionals to skip those not needed

module "log-export-dataset" {
  source        = "../../../modules/bigquery-dataset"
  count         = contains(local.log_types, "bigquery") ? 1 : 0
  project_id    = module.log-export-project.project_id
  id            = "audit_export"
  friendly_name = "Audit logs export."
  location      = var.locations.bq
}

module "log-export-gcs" {
  source        = "../../../modules/gcs"
  count         = contains(local.log_types, "storage") ? 1 : 0
  project_id    = module.log-export-project.project_id
  name          = "audit-logs-0"
  prefix        = local.prefix
  location      = var.locations.gcs
  storage_class = local.gcs_storage_class
}

module "log-export-logbucket" {
  source      = "../../../modules/logging-bucket"
  for_each    = toset([for k, v in var.log_sinks : k if v.type == "logging"])
  parent_type = "project"
  parent      = module.log-export-project.project_id
  id          = "audit-logs-${each.key}"
  location    = var.locations.logging
}

module "log-export-pubsub" {
  source     = "../../../modules/pubsub"
  for_each   = toset([for k, v in var.log_sinks : k if v.type == "pubsub"])
  project_id = module.log-export-project.project_id
  name       = "audit-logs-${each.key}"
  regions    = var.locations.pubsub
}
