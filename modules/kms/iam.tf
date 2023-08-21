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
  key_iam = flatten([
    for key, roles in var.key_iam : [
      for role, members in roles : {
        key     = key
        role    = role
        members = members
      }
    ]
  ])
  key_iam_bindings = flatten([
    for key, roles in var.key_iam_bindings : [
      for role, data in roles : {
        key       = key
        role      = role
        members   = data.members
        condition = data.condition
      }
    ]
  ])
}

resource "google_kms_key_ring_iam_binding" "authoritative" {
  for_each    = var.iam
  key_ring_id = local.keyring.id
  role        = each.key
  members     = each.value
}

resource "google_kms_key_ring_iam_binding" "bindings" {
  for_each    = var.iam_bindings
  key_ring_id = local.keyring.id
  role        = each.key
  members     = each.value.members
  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = each.value.condition.expression
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

resource "google_kms_key_ring_iam_member" "bindings" {
  for_each    = var.iam_bindings_additive
  key_ring_id = local.keyring.id
  role        = each.value.role
  member      = each.value.member
  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = each.value.condition.expression
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

resource "google_kms_crypto_key_iam_binding" "authoritative" {
  for_each = {
    for binding in local.key_iam :
    "${binding.key}.${binding.role}" => binding
  }
  role          = each.value.role
  crypto_key_id = google_kms_crypto_key.default[each.value.key].id
  members       = each.value.members
}

resource "google_kms_crypto_key_iam_binding" "bindings" {
  for_each = {
    for binding in local.key_iam_bindings :
    "${binding.key}.${binding.role}" => binding
  }
  role          = each.value.role
  crypto_key_id = google_kms_crypto_key.default[each.value.key].id
  members       = each.value.members
  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = each.value.condition.expression
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

resource "google_kms_crypto_key_iam_member" "members" {
  for_each      = var.key_iam_bindings_additive
  crypto_key_id = google_kms_crypto_key.default[each.value.key].id
  role          = each.value.role
  member        = each.value.member
  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = each.value.condition.expression
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}
