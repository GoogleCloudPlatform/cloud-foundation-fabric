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
  iam_pairs = concat([], distinct([
    for name, roles in var.iam_roles :
    [for role in roles : { name = name, role = role }]
  ])...)
  iam_keypairs = {
    for pair in local.iam_pairs :
    "${pair.name}-${pair.role}" => pair
  }
  key_attributes = {
    for name in var.keys :
    name => merge(lookup(var.key_attributes, name, {}), var.key_defaults)
  }
}

resource "google_kms_key_ring" "key_ring" {
  name     = var.keyring
  project  = var.project_id
  location = var.location
}

resource "google_kms_crypto_key" "keys" {
  for_each        = toset(var.keys)
  name            = each.value
  key_ring        = google_kms_key_ring.key_ring.self_link
  rotation_period = local.key_attributes[each.value].rotation_period

  dynamic lifecycle {
    for_each = local.key_attributes[each.value].protected ? [""] : []
    content {
      prevent_destroy = true
    }
  }
}

resource "google_kms_crypto_key_iam_binding" "bindings" {
  for_each      = local.iam_keypairs
  role          = each.value.role
  crypto_key_id = google_kms_crypto_key.keys[each.value.name].self_link
  members = lookup(
    lookup(var.iam_members, each.value.name, {}), each.value.role, []
  )
}
