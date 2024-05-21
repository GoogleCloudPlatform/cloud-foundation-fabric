# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

resource "google_project_service_identity" "secretmanager" {
  provider = google-beta
  project  = var.project_id
  service  = "secretmanager.googleapis.com"
}

resource "google_project_iam_binding" "bindings" {
  project = var.project_id
  role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members = ["serviceAccount:${resource.google_project_service_identity.secretmanager.email}"]
}

resource "google_kms_key_ring" "key_rings" {
  for_each = toset([var.region_primary, var.region_secondary])
  name     = "keyring-${each.key}"
  project  = var.project_id
  location = each.value
}

resource "google_kms_crypto_key" "keys" {
  for_each        = toset([var.region_primary, var.region_secondary])
  name            = "crypto-key-${each.key}"
  key_ring        = google_kms_key_ring.key_rings[each.key].id
  rotation_period = "100000s"
}

resource "google_kms_key_ring" "keyring_global" {
  name     = "keyring-global"
  project  = var.project_id
  location = "global"
}

resource "google_kms_crypto_key" "key_global" {
  name            = "crypto-key-example-global"
  key_ring        = google_kms_key_ring.keyring_global.id
  rotation_period = "100000s"
  depends_on      = [google_project_iam_binding.bindings]
}
