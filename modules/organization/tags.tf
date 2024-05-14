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
  _tag_iam = flatten([
    for k, v in local.tags : [
      for role in keys(v.iam) : {
        # we cycle on keys here so we don't risk injecting dynamic values
        role   = role
        tag    = k
        tag_id = v.id
      }
    ]
  ])
  _tag_value_iam = flatten([
    for k, v in local.tag_values : [
      for role in v.roles : {
        id   = v.id
        key  = v.key
        name = v.name
        role = role
        tag  = v.tag
      }
    ]
  ])
  _tag_values = flatten([
    for k, v in local.tags : [
      for vk, vv in v.values : {
        description           = vv.description,
        key                   = "${k}/${vk}"
        iam_bindings          = keys(vv.iam_bindings)
        iam_bindings_additive = keys(vv.iam_bindings_additive)
        id                    = try(vv.id, null)
        name                  = vk
        # we only store keys here so we don't risk injecting dynamic values
        roles       = keys(vv.iam)
        tag         = k
        tag_id      = v.id
        tag_network = try(v.network, null) != null
      }
    ]
  ])
  tag_iam = {
    for t in local._tag_iam : "${t.tag}:${t.role}" => t
  }
  tag_iam_bindings = merge([
    for k, v in local.tags : {
      for bk in keys(v.iam_bindings) : "${k}:${bk}" => {
        binding = bk
        tag     = k
        tag_id  = v.id
      }
    }
  ]...)
  tag_iam_bindings_additive = merge([
    for k, v in local.tags : {
      for bk in keys(v.iam_bindings_additive) : "${k}:${bk}" => {
        binding = bk
        tag     = k
        tag_id  = v.id
      }
    }
  ]...)
  tag_value_iam = {
    for v in local._tag_value_iam : "${v.key}:${v.role}" => v
  }
  tag_value_iam_bindings = merge([
    for k, v in local.tag_values : {
      for bk in v.iam_bindings : "${k}:${bk}" => {
        binding = bk
        id      = v.id
        key     = k
        name    = v.name
        tag     = v.tag
        tag_id  = v.id
      }
    }
  ]...)
  tag_value_iam_bindings_additive = merge([
    for k, v in local.tag_values : {
      for bk in v.iam_bindings_additive : "${k}:${bk}" => {
        binding = bk
        id      = v.id
        key     = k
        name    = v.name
        tag     = v.tag
        tag_id  = v.id
      }
    }
  ]...)
  tag_values = {
    for v in local._tag_values : v.key => v
  }
  tags = merge(var.tags, var.network_tags)
}

# keys

resource "google_tags_tag_key" "default" {
  for_each = { for k, v in local.tags : k => v if v.id == null }
  parent   = var.organization_id
  purpose = (
    lookup(each.value, "network", null) == null ? null : "GCE_FIREWALL"
  )
  purpose_data = (
    lookup(each.value, "network", null) == null ? null : { network = each.value.network }
  )
  short_name  = each.key
  description = each.value.description
  depends_on = [
    google_organization_iam_binding.authoritative,
    google_organization_iam_binding.bindings,
    google_organization_iam_member.bindings
  ]
}

resource "google_tags_tag_key_iam_binding" "default" {
  for_each = local.tag_iam
  tag_key = (
    each.value.tag_id == null
    ? google_tags_tag_key.default[each.value.tag].id
    : each.value.tag_id
  )
  role = each.value.role
  members = coalesce(
    local.tags[each.value.tag]["iam"][each.value.role], []
  )
}

resource "google_tags_tag_key_iam_binding" "bindings" {
  for_each = local.tag_iam_bindings
  tag_key = (
    each.value.tag_id == null
    ? google_tags_tag_key.default[each.value.tag].id
    : each.value.tag_id
  )
  role = local.tags[each.value.tag]["iam_bindings"][each.value.binding].role
  members = (
    local.tags[each.value.tag]["iam_bindings"][each.value.binding].members
  )
}

resource "google_tags_tag_key_iam_member" "bindings" {
  for_each = local.tag_iam_bindings_additive
  tag_key = (
    each.value.tag_id == null
    ? google_tags_tag_key.default[each.value.tag].id
    : each.value.tag_id
  )
  role   = local.tags[each.value.tag]["iam_bindings_additive"][each.value.binding].role
  member = local.tags[each.value.tag]["iam_bindings_additive"][each.value.binding].member
}

# values

resource "google_tags_tag_value" "default" {
  for_each = { for k, v in local.tag_values : k => v if v.id == null }
  parent = (
    each.value.tag_id == null
    ? google_tags_tag_key.default[each.value.tag].id
    : each.value.tag_id
  )
  short_name  = each.value.name
  description = each.value.description
}

resource "google_tags_tag_value_iam_binding" "default" {
  for_each = local.tag_value_iam
  tag_value = (
    each.value.id == null
    ? google_tags_tag_value.default[each.value.key].id
    : each.value.id
  )
  role = each.value.role
  members = coalesce(
    local.tags[each.value.tag]["values"][each.value.name]["iam"][each.value.role],
    []
  )
}

resource "google_tags_tag_value_iam_binding" "bindings" {
  for_each = local.tag_value_iam_bindings
  tag_value = (
    each.value.id == null
    ? google_tags_tag_value.default[each.value.key].id
    : each.value.id
  )
  role = (
    local.tags[each.value.tag]["values"][each.value.name]["iam_bindings"][each.value.binding].role
  )
  members = (
    local.tags[each.value.tag]["values"][each.value.name]["iam_bindings"][each.value.binding].members
  )
}

resource "google_tags_tag_value_iam_member" "bindings" {
  for_each = local.tag_value_iam_bindings_additive
  tag_value = (
    each.value.id == null
    ? google_tags_tag_value.default[each.value.key].id
    : each.value.id
  )
  role = (
    local.tags[each.value.tag]["values"][each.value.name]["iam_bindings_additive"][each.value.binding].role
  )
  member = (
    local.tags[each.value.tag]["values"][each.value.name]["iam_bindings_additive"][each.value.binding].member
  )
}

# bindings

resource "google_tags_tag_binding" "binding" {
  for_each  = var.tag_bindings
  parent    = "//cloudresourcemanager.googleapis.com/${var.organization_id}"
  tag_value = each.value
}
