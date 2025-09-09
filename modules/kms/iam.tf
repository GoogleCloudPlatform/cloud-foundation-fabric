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
    for k, v in var.keys : [
      for role, members in v.iam : {
        key     = k
        role    = role
        members = members
      }
    ]
  ])
  key_iam_bindings = merge([
    for k, v in var.keys : {
      for binding_key, data in v.iam_bindings :
      binding_key => {
        key       = k
        role      = data.role
        members   = data.members
        condition = data.condition
      }
    }
  ]...)
  key_iam_bindings_additive = merge([
    for k, v in var.keys : {
      for binding_key, data in v.iam_bindings_additive :
      binding_key => {
        key       = k
        role      = data.role
        member    = data.member
        condition = data.condition
      }
    }
  ]...)
}

resource "google_kms_key_ring_iam_binding" "authoritative" {
  for_each    = var.iam
  key_ring_id = local.keyring.id
  role        = lookup(local.ctx.custom_roles, each.key, each.key)
  members = [
    for v in each.value :
    lookup(local.ctx.iam_principals, v, v)
  ]
}

resource "google_kms_key_ring_iam_binding" "bindings" {
  for_each    = var.iam_bindings
  key_ring_id = local.keyring.id
  role        = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  members = [
    for v in each.value.members : lookup(local.ctx.iam_principals, v, v)
  ]
  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression = templatestring(
        each.value.condition.expression, var.context.condition_vars
      )
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

resource "google_kms_key_ring_iam_member" "bindings" {
  for_each    = var.iam_bindings_additive
  key_ring_id = local.keyring.id
  role        = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  member      = lookup(local.ctx.iam_principals, each.value.member, each.value.member)
  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression = templatestring(
        each.value.condition.expression, var.context.condition_vars
      )
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
  role          = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  crypto_key_id = google_kms_crypto_key.default[each.value.key].id
  members = [
    for v in each.value.members :
    lookup(local.ctx.iam_principals, v, v)
  ]
}

resource "google_kms_crypto_key_iam_binding" "bindings" {
  for_each      = local.key_iam_bindings
  role          = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  crypto_key_id = google_kms_crypto_key.default[each.value.key].id
  members = [
    for v in each.value.members :
    lookup(local.ctx.iam_principals, v, v)
  ]
  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression = templatestring(
        each.value.condition.expression, var.context.condition_vars
      )
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

resource "google_kms_crypto_key_iam_member" "members" {
  for_each      = local.key_iam_bindings_additive
  crypto_key_id = google_kms_crypto_key.default[each.value.key].id
  role          = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  member        = lookup(local.ctx.iam_principals, each.value.member, each.value.member)
  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression = templatestring(
        each.value.condition.expression, var.context.condition_vars
      )
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}
