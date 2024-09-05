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

output "id" {
  description = "Fully qualified keyring id."
  value       = local.keyring.id
  depends_on = [
    google_kms_key_ring_iam_binding.authoritative,
    google_kms_key_ring_iam_binding.bindings,
    google_kms_key_ring_iam_member.bindings,
    google_kms_crypto_key_iam_binding.authoritative,
    google_kms_crypto_key_iam_binding.bindings,
    google_kms_crypto_key_iam_member.members
  ]
}

output "import_job" {
  description = "Keyring import job resources."
  value       = google_kms_key_ring_import_job.default
  depends_on = [
    google_kms_key_ring_iam_binding.authoritative,
    google_kms_key_ring_iam_binding.bindings,
    google_kms_key_ring_iam_member.bindings,
    google_kms_crypto_key_iam_binding.authoritative,
    google_kms_crypto_key_iam_binding.bindings,
    google_kms_crypto_key_iam_member.members
  ]
}

output "key_ids" {
  description = "Fully qualified key ids."
  value = {
    for name, resource in google_kms_crypto_key.default :
    name => resource.id
  }
  depends_on = [
    google_kms_crypto_key_iam_binding.authoritative,
    google_kms_crypto_key_iam_binding.bindings,
    google_kms_crypto_key_iam_member.members
  ]
}

output "keyring" {
  description = "Keyring resource."
  value       = local.keyring
  depends_on = [
    google_kms_key_ring_iam_binding.authoritative,
    google_kms_key_ring_iam_binding.bindings,
    google_kms_crypto_key_iam_member.members,
    google_kms_crypto_key_iam_binding.authoritative,
    google_kms_crypto_key_iam_binding.bindings,
    google_kms_crypto_key_iam_member.members,
  ]
}

output "keys" {
  description = "Key resources."
  value       = google_kms_crypto_key.default
  depends_on = [
    google_kms_key_ring_iam_binding.authoritative,
    google_kms_key_ring_iam_binding.bindings,
    google_kms_key_ring_iam_member.bindings,
    google_kms_crypto_key_iam_binding.authoritative,
    google_kms_crypto_key_iam_binding.bindings,
    google_kms_crypto_key_iam_member.members
  ]
}

output "location" {
  description = "Keyring location."
  value       = local.keyring.location
  depends_on = [
    google_kms_key_ring_iam_binding.authoritative,
    google_kms_key_ring_iam_binding.bindings,
    google_kms_key_ring_iam_member.bindings,
    google_kms_crypto_key_iam_binding.authoritative,
    google_kms_crypto_key_iam_binding.bindings,
    google_kms_crypto_key_iam_member.members
  ]
}

output "name" {
  description = "Keyring name."
  value       = local.keyring.name
  depends_on = [
    google_kms_key_ring_iam_binding.authoritative,
    google_kms_key_ring_iam_binding.bindings,
    google_kms_key_ring_iam_member.bindings,
    google_kms_crypto_key_iam_binding.authoritative,
    google_kms_crypto_key_iam_binding.bindings,
    google_kms_crypto_key_iam_member.members
  ]
}
