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
  gcs_storage_class = (
    length(split("-", var.log_locations.storage)) < 2
    ? "MULTI_REGIONAL"
    : "REGIONAL"
  )
  log_types = toset([for k, v in var.log_sinks : v.type])

  _log_keys = var.enable_features.encryption ? {
    bq      = var.enable_features.log_sink ? ["projects/${module.sec-project.0.project_id}/locations/${var.log_locations.bq}/keyRings/${var.log_locations.bq}/cryptoKeys/bq"] : null
    pubsub  = var.enable_features.log_sink ? ["projects/${module.sec-project.0.project_id}/locations/${var.log_locations.pubsub}/keyRings/${var.log_locations.pubsub}/cryptoKeys/pubsub"] : null
    storage = var.enable_features.log_sink ? ["projects/${module.sec-project.0.project_id}/locations/${var.log_locations.storage}/keyRings/${var.log_locations.storage}/cryptoKeys/storage"] : null
  } : {}

  log_keys = {
    for service, key in local._log_keys : service => key if key != null
  }
}

module "log-export-project" {
  count           = var.enable_features.log_sink ? 1 : 0
  source          = "../../../modules/project"
  name            = var.project_config.project_ids["audit-logs"]
  parent          = module.folder.id
  billing_account = var.project_config.billing_account_id
  project_create  = var.project_config.billing_account_id != null
  prefix          = var.project_config.billing_account_id == null ? null : var.prefix
  group_iam = {
    (local.groups.workload-security) = [
      "roles/editor"
    ]
  }
  iam = {
    # "roles/owner" = [module.automation-tf-bootstrap-sa.iam_email]
  }
  services = [
    "bigquery.googleapis.com",
    "pubsub.googleapis.com",
    "storage.googleapis.com",
    "stackdriver.googleapis.com"
  ]
  service_encryption_key_ids = var.enable_features.encryption ? local.log_keys : {}

  depends_on = [
    module.log-kms
  ]
}

# one log export per type, with conditionals to skip those not needed

module "log-export-dataset" {
  source         = "../../../modules/bigquery-dataset"
  count          = var.enable_features.log_sink && contains(local.log_types, "bigquery") ? 1 : 0
  project_id     = module.log-export-project[0].project_id
  id             = "${var.prefix}_audit_export"
  friendly_name  = "Audit logs export."
  location       = replace(var.log_locations.bq, "europe", "EU")
  encryption_key = var.enable_features.encryption ? module.log-kms[var.log_locations.bq].keys["bq"].id : false
}

module "log-export-gcs" {
  source         = "../../../modules/gcs"
  count          = var.enable_features.log_sink && contains(local.log_types, "storage") ? 1 : 0
  project_id     = module.log-export-project[0].project_id
  name           = "audit-logs"
  prefix         = var.prefix
  location       = replace(var.log_locations.storage, "europe", "EU")
  storage_class  = local.gcs_storage_class
  encryption_key = var.enable_features.encryption ? module.log-kms[var.log_locations.storage].keys["storage"].id : null
}

module "log-export-logbucket" {
  source      = "../../../modules/logging-bucket"
  for_each    = var.enable_features.log_sink ? toset([for k, v in var.log_sinks : k if v.type == "logging"]) : []
  parent_type = "project"
  parent      = module.log-export-project[0].project_id
  id          = "audit-logs-${each.key}"
  location    = var.log_locations.logging
  #TODO check if logging bucket support encryption.
}

module "log-export-pubsub" {
  source     = "../../../modules/pubsub"
  for_each   = toset([for k, v in var.log_sinks : k if v.type == "pubsub" && var.enable_features.log_sink])
  project_id = module.log-export-project[0].project_id
  name       = "audit-logs-${each.key}"
  regions    = [var.log_locations.pubsub]
  kms_key    = var.enable_features.encryption ? module.log-kms[var.log_locations.pubsub].keys["pubsub"].id : null
}
