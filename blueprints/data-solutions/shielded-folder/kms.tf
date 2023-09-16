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

# tfdoc:file:description Security project, Cloud KMS and Secret Manager resources.

locals {
  # list of locations with keys
  kms_locations = distinct(flatten([
    for k, v in var.kms_keys : v.locations
  ]))
  # map { location -> { key_name -> key_details } }
  kms_locations_keys = {
    for loc in local.kms_locations :
    loc => {
      for k, v in var.kms_keys :
      k => v
      if contains(v.locations, loc)
    }
  }
  kms_log_locations = distinct(flatten([
    for k, v in local.kms_log_sink_keys : compact(v.locations)
  ]))
  kms_log_sink_keys = {
    "storage" = {
      locations       = [var.log_locations.storage]
      rotation_period = "7776000s"
    }
    "bq" = {
      locations       = [var.log_locations.bq]
      rotation_period = "7776000s"
    }
    "pubsub" = {
      locations       = [var.log_locations.pubsub]
      rotation_period = "7776000s"
    }
  }
  kms_log_locations_keys = {
    for loc in local.kms_log_locations : loc => {
      for k, v in local.kms_log_sink_keys : k => v if contains(v.locations, loc)
    }
  }
}

module "sec-project" {
  count           = var.enable_features.encryption ? 1 : 0
  source          = "../../../modules/project"
  name            = var.project_config.project_ids["sec-core"]
  parent          = module.folder.id
  billing_account = var.project_config.billing_account_id
  project_create = (
    var.project_config.billing_account_id != null && var.enable_features.encryption
  )
  prefix = (
    var.project_config.billing_account_id == null ? null : var.prefix
  )
  group_iam = {
    (local.groups.workload-security) = [
      "roles/editor"
    ]
  }
  services = [
    "cloudkms.googleapis.com",
    "secretmanager.googleapis.com",
    "stackdriver.googleapis.com"
  ]
}

module "sec-kms" {
  for_each = (
    var.enable_features.encryption
    ? toset(local.kms_locations)
    : toset([])
  )
  source     = "../../../modules/kms"
  project_id = module.sec-project[0].project_id
  keyring = {
    location = each.key
    name     = "sec-${each.key}"
  }
  keys = local.kms_locations_keys[each.key]
}

module "log-kms" {
  for_each   = var.enable_features.encryption ? toset(local.kms_log_locations) : toset([])
  source     = "../../../modules/kms"
  project_id = module.sec-project[0].project_id
  keyring = {
    location = each.key
    name     = "log-${each.key}"
  }
  keys = local.kms_log_locations_keys[each.key]
}
