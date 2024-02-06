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
  keyring = (
    var.keyring_create
    ? google_kms_key_ring.default.0
    : data.google_kms_key_ring.default.0
  )
}

data "google_kms_key_ring" "default" {
  count    = var.keyring_create ? 0 : 1
  project  = var.project_id
  name     = var.keyring.name
  location = var.keyring.location
}

resource "google_kms_key_ring" "default" {
  count    = var.keyring_create ? 1 : 0
  project  = var.project_id
  name     = var.keyring.name
  location = var.keyring.location
}

resource "google_kms_crypto_key" "default" {
  for_each                      = var.keys
  key_ring                      = local.keyring.id
  name                          = each.key
  rotation_period               = each.value.rotation_period
  labels                        = each.value.labels
  purpose                       = each.value.purpose
  skip_initial_version_creation = each.value.skip_initial_version_creation

  dynamic "version_template" {
    for_each = each.value.version_template == null ? [] : [""]
    content {
      algorithm        = each.value.version_template.algorithm
      protection_level = each.value.version_template.protection_level
    }
  }
}

resource "google_kms_key_ring_import_job" "default" {
  count            = var.import_job != null ? 1 : 0
  key_ring         = local.keyring.id
  import_job_id    = var.import_job.id
  import_method    = var.import_job.import_method
  protection_level = var.import_job.protection_level
}