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

resource "google_compute_router_route_policy" "default" {
  for_each = var.router_config.route_policies
  project  = local.project_id
  region   = local.region
  router   = local.router
  name     = each.key
  type     = each.value.type == "IMPORT" ? "ROUTE_POLICY_TYPE_IMPORT" : each.value.type == "EXPORT" ? "ROUTE_POLICY_TYPE_EXPORT" : null

  dynamic "terms" {
    for_each = each.value.terms
    content {
      priority = terms.value.priority
      match {
        expression  = terms.value.match.expression
        title       = terms.value.match.title
        description = terms.value.match.description
        location    = terms.value.match.location
      }
      dynamic "actions" {
        for_each = terms.value.actions
        content {
          expression  = actions.value.expression
          title       = actions.value.title
          description = actions.value.description
          location    = actions.value.location
        }
      }
    }
  }
}
