/**
 * Copyright 2021 Google LLC
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

output "keyring" {
  description = "Keyring resource."
  value       = local.keyring
  depends_on = [
    google_kms_key_ring_iam_binding.default
  ]
}

output "location" {
  description = "Keyring location."
  value       = local.keyring.location
  depends_on = [
    google_kms_key_ring_iam_binding.default
  ]
}

output "name" {
  description = "Keyring name."
  value       = local.keyring.name
  depends_on = [
    google_kms_key_ring_iam_binding.default
  ]
}

output "self_link" {
  description = "Keyring self link."
  value       = local.keyring.self_link
  depends_on = [
    google_kms_key_ring_iam_binding.default
  ]
}

output "keys" {
  description = "Key resources."
  value       = google_kms_crypto_key.default
  depends_on = [
    google_kms_crypto_key_iam_binding.default
  ]
}

output "key_self_links" {
  description = "Key self links."
  value = {
    for name, resource in google_kms_crypto_key.default :
    name => resource.self_link
  }
  depends_on = [
    google_kms_crypto_key_iam_binding.default
  ]
}
