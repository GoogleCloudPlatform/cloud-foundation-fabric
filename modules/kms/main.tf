/**
 * Copyright 2019 Google LLC
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
  # distinct is needed to make the expanding function argument work
  attributes = {
    for key, attrs in var.keys : key => try(
      var.key_attributes[key], var.key_attributes_defaults
    )
  }
  iam_pairs = flatten([
    for name, roles in var.keys_iam_roles :
    [for role in roles : { name = name, role = role }]
  ])
  iam_keypairs = {
    for pair in local.iam_pairs :
    "${pair.name}-${pair.role}" => pair
  }
  keyring = (
    var.keyring_create
    ? google_kms_key_ring.default
    : data.google_kms_key_ring.default
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

resource "google_kms_key_ring_iam_binding" "default" {
  for_each    = toset(var.iam_roles)
  key_ring_id = local.keyring.self_link
  role        = each.value
  members     = lookup(var.iam_members, each.value, [])
}

resource "google_kms_crypto_key" "default" {
  for_each        = var.keys
  key_ring        = local.keyring.self_link
  name            = each.key
  rotation_period = try(each.value.rotation_period, null)
  labels          = try(each.value.labels, null)
  purpose         = try(local.attributes[each.key], null)
  dynamic version_template {
    for_each = local.attributes[each.key].version_template == null ? [] : [""]
    content {
      algorithm        = local.attributes[each.key].version_template.algorithm
      protection_level = local.attributes[each.key].version_template.protection_level
    }
  }
}

resource "google_kms_crypto_key_iam_binding" "default" {
  for_each      = local.iam_keypairs
  role          = each.value.role
  crypto_key_id = google_kms_crypto_key.default[each.value.name].self_link
  members = lookup(
    lookup(var.keys_iam_members, each.value.name, {}), each.value.role, []
  )
}
