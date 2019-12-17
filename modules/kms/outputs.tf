/**
 * Copyright 2018 Google LLC
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
  value       = google_kms_key_ring.key_ring
}

output "name" {
  description = "Keyring self link."
  value       = google_kms_key_ring.key_ring.self_link
}

output "self_link" {
  description = "Keyring self link."
  value       = google_kms_key_ring.key_ring.self_link
}

output "keys" {
  description = "Key resources."
  value       = [for name in var.keys : google_kms_crypto_key.keys[name]]
}

output "key_self_links" {
  description = "Key self links."
  value       = [for name in var.keys : google_kms_crypto_key.keys[name].self_link]
}
