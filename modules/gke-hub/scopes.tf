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

locals {
  _scope_memberships_from_clusters = {
    for k, v in var.clusters :
    "${v.scope}/${k}" => {
      binding_id    = "${basename(v.scope)}-${replace(k, "/", "-")}"
      membership_id = k
      scope         = v.scope
    }
    if v.scope != null
  }
  _scope_memberships_from_scopes = {
    for m in flatten([
      for sk, sv in var.scopes : [
        for m in sv.cluster_memberships : {
          binding_id    = "${basename(sk)}-${replace(m, "/", "-")}"
          membership_id = m
          scope         = sk
        }
      ]
    ]) : "${m.scope}/${m.membership_id}" => m
  }
  _scope_memberships = merge(
    local._scope_memberships_from_scopes,
    local._scope_memberships_from_clusters
  )
  _scope_namespaces = {
    for n in flatten([
      for sk, sv in var.scopes : [
        for nk, nv in sv.namespaces : {
          labels           = nv.labels
          namespace_id     = nk
          namespace_labels = nv.namespace_labels
          scope_id         = sk
        }
      ]
    ]) : "${n.scope_id}/${n.namespace_id}" => n
  }
  _scope_rbac_role_bindings = {
    for r in flatten([
      for sk, sv in var.scopes : [
        for rk, rv in sv.rbac_role_bindings : {
          custom_role     = rv.custom_role
          group           = rv.group
          labels          = rv.labels
          role            = rv.role
          role_binding_id = rk
          scope_id        = sk
          user            = rv.user
        }
      ]
    ]) : "${r.scope_id}/${r.role_binding_id}" => r
  }
}

resource "google_gke_hub_scope" "default" {
  provider         = google-beta
  for_each         = var.scopes
  project          = var.project_id
  scope_id         = each.key
  labels           = each.value.labels
  namespace_labels = each.value.namespace_labels
}

resource "google_gke_hub_membership_binding" "default" {
  provider              = google-beta
  for_each              = local._scope_memberships
  project               = var.project_id
  location              = coalesce(var.location, "global")
  membership_id         = each.value.membership_id
  membership_binding_id = each.value.binding_id
  scope = (
    try(
      google_gke_hub_scope.default[each.value.scope].name,
      each.value.scope
    )
  )
  depends_on = [
    google_gke_hub_membership.default,
    google_gke_hub_scope.default,
  ]
}

resource "google_gke_hub_namespace" "default" {
  provider           = google-beta
  for_each           = local._scope_namespaces
  project            = var.project_id
  scope_id           = each.value.scope_id
  scope              = google_gke_hub_scope.default[each.value.scope_id].name
  scope_namespace_id = each.value.namespace_id
  labels             = each.value.labels
  namespace_labels   = each.value.namespace_labels
}

resource "google_gke_hub_scope_rbac_role_binding" "default" {
  provider = google-beta
  for_each = local._scope_rbac_role_bindings
  project  = var.project_id
  scope_id = (
    google_gke_hub_scope.default[each.value.scope_id].scope_id
  )
  scope_rbac_role_binding_id = each.value.role_binding_id
  group                      = each.value.group
  labels                     = each.value.labels
  user                       = each.value.user
  role {
    custom_role     = each.value.custom_role
    predefined_role = each.value.role
  }
}
