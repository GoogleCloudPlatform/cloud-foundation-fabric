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

output "cluster_ids" {
  description = "Fully qualified ids of all clusters."
  value = {
    for k, v in google_gke_hub_membership.default : k => v.id
  }
  depends_on = [
    google_gke_hub_membership.default,
    google_gke_hub_feature.default,
    google_gke_hub_feature_membership.default,
    google_gke_hub_feature_membership.policycontroller,
    google_gke_hub_feature_membership.servicemesh,
  ]
}

output "membership_binding_ids" {
  description = "Membership binding IDs."
  value = {
    for k, v in google_gke_hub_membership_binding.default : k => v.id
  }
}

output "membership_bindings" {
  description = "Fleet membership bindings."
  value       = google_gke_hub_membership_binding.default
}

output "namespace_ids" {
  description = "Namespace IDs."
  value = {
    for k, v in google_gke_hub_namespace.default : k => v.id
  }
}

output "namespaces" {
  description = "Fleet namespaces."
  value       = google_gke_hub_namespace.default
}

output "scope_ids" {
  description = "Scope IDs."
  value = {
    for k, v in google_gke_hub_scope.default : k => v.id
  }
  depends_on = [
    google_gke_hub_membership_binding.default,
    google_gke_hub_namespace.default,
    google_gke_hub_scope_rbac_role_binding.default,
  ]
}

output "scope_rbac_role_binding_ids" {
  description = "Scope RBAC role binding IDs."
  value = {
    for k, v in google_gke_hub_scope_rbac_role_binding.default : k => v.id
  }
}

output "scope_rbac_role_bindings" {
  description = "Fleet scope RBAC role bindings."
  value       = google_gke_hub_scope_rbac_role_binding.default
}

output "scopes" {
  description = "Fleet scopes."
  value       = google_gke_hub_scope.default
  depends_on = [
    google_gke_hub_membership_binding.default,
    google_gke_hub_namespace.default,
    google_gke_hub_scope_rbac_role_binding.default,
  ]
}
