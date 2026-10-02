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

# tfdoc:file:description IAP tunnel IAM bindings.

resource "google_iap_tunnel_instance_iam_binding" "authoritative" {
  for_each = var.iap_tunnel_iam
  project  = local.project_id
  zone     = local.zone
  instance = var.name
  role     = lookup(local.ctx.custom_roles, each.key, each.key)
  members = [
    for m in each.value : lookup(local.ctx.iam_principals, m, m)
  ]
  depends_on = [google_compute_instance.default]
}

resource "google_iap_tunnel_instance_iam_binding" "bindings" {
  for_each = var.iap_tunnel_iam_bindings
  project  = local.project_id
  zone     = local.zone
  instance = var.name
  role     = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  members = [
    for m in each.value.members : lookup(local.ctx.iam_principals, m, m)
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
  depends_on = [google_compute_instance.default]
}

resource "google_iap_tunnel_instance_iam_member" "bindings" {
  for_each = var.iap_tunnel_iam_bindings_additive
  project  = local.project_id
  zone     = local.zone
  instance = var.name
  role     = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  member = lookup(
    local.ctx.iam_principals, each.value.member, each.value.member
  )
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
  depends_on = [google_compute_instance.default]
}
