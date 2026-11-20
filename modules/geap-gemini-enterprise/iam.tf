/**
 * Copyright 2026 Google LLC
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

# tfdoc:file:description App-level Discovery Engine IAM bindings.

locals {
  _app_all_raw_principals = flatten([
    for k, v in local.apps : concat(
      flatten(values(v.iam)),
      keys(v.iam_by_principals),
      flatten([for b in values(v.iam_bindings) : b.members]),
      [for b in values(v.iam_bindings_additive) : b.member]
    )
  ])
  _app_all_resolved_principals = distinct([
    for p in local._app_all_raw_principals :
    lookup(local.ctx.iam_principals, p, p)
  ])
  _app_iam_by_principals = {
    for k, v in local.apps : k => {
      for r in distinct(flatten(values(v.iam_by_principals))) : r => [
        for pk, pv in v.iam_by_principals :
        pk if contains(pv, r)
      ]
    }
  }
  _app_iam_merged = {
    for k, v in local.apps : k => {
      for role in distinct(concat(
        keys(v.iam),
        keys(local._app_iam_by_principals[k])
        )) : role => distinct(concat(
        try(v.iam[role], []),
        try(local._app_iam_by_principals[k][role], [])
      ))
    }
  }
  app_iam = merge([
    for k, v in local.apps : {
      for role, members in local._app_iam_merged[k] :
      "${k}/${role}" => {
        collection_id = v.collection_id
        engine_id     = v.engine_id
        members       = members
        role          = role
      }
    }
  ]...)
  app_iam_bindings = merge([
    for k, v in local.apps : {
      for bk, bv in v.iam_bindings :
      "${k}/${bk}" => {
        collection_id = v.collection_id
        engine_id     = v.engine_id
        members       = bv.members
        role          = bv.role
      }
    }
  ]...)
  app_iam_bindings_additive = merge([
    for k, v in local.apps : {
      for bk, bv in v.iam_bindings_additive :
      "${k}/${bk}" => {
        collection_id = v.collection_id
        engine_id     = v.engine_id
        member        = bv.member
        role          = bv.role
      }
    }
  ]...)
  app_iam_principals = toset([
    for p in local._app_all_resolved_principals : p
    if !contains(["allUsers", "allAuthenticatedUsers"], p)
    && !startswith(p, "deleted:")
  ])
}

resource "google_discovery_engine_search_engine_iam_binding" "authoritative" {
  for_each      = local.app_iam
  project       = local.project_id
  location      = local.location
  collection_id = each.value.collection_id
  engine_id     = each.value.engine_id
  role = lookup(
    local.ctx.custom_roles, each.value.role, each.value.role
  )
  members = [
    for m in each.value.members :
    lookup(local.ctx.iam_principals, m, m)
  ]

  depends_on = [
    google_discovery_engine_search_engine.default,
  ]
}

resource "google_discovery_engine_search_engine_iam_binding" "bindings" {
  for_each      = local.app_iam_bindings
  project       = local.project_id
  location      = local.location
  collection_id = each.value.collection_id
  engine_id     = each.value.engine_id
  role = lookup(
    local.ctx.custom_roles, each.value.role, each.value.role
  )
  members = [
    for m in each.value.members :
    lookup(local.ctx.iam_principals, m, m)
  ]

  depends_on = [
    google_discovery_engine_search_engine.default,
  ]
}

resource "google_discovery_engine_search_engine_iam_member" "bindings" {
  for_each      = local.app_iam_bindings_additive
  project       = local.project_id
  location      = local.location
  collection_id = each.value.collection_id
  engine_id     = each.value.engine_id
  role = lookup(
    local.ctx.custom_roles, each.value.role, each.value.role
  )
  member = lookup(
    local.ctx.iam_principals, each.value.member, each.value.member
  )

  depends_on = [
    google_discovery_engine_search_engine.default,
  ]
}
