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

output "id" {
  description = "Fully qualified security policy id."
  value = (
    local.is_global
    ? google_compute_security_policy.global[0].id
    : google_compute_region_security_policy.regional[0].id
  )
  depends_on = [
    google_compute_security_policy_rule.global,
    google_compute_security_policy_rule.global_default,
    google_compute_region_security_policy_rule.regional,
    google_compute_region_security_policy_rule.regional_default
  ]
}

output "name" {
  description = "Security policy name."
  value       = var.name
  depends_on = [
    google_compute_security_policy.global,
    google_compute_region_security_policy.regional
  ]
}

output "self_link" {
  description = "Security policy self link."
  value = (
    local.is_global
    ? google_compute_security_policy.global[0].self_link
    : google_compute_region_security_policy.regional[0].self_link
  )
  depends_on = [
    google_compute_security_policy_rule.global,
    google_compute_security_policy_rule.global_default,
    google_compute_region_security_policy_rule.regional,
    google_compute_region_security_policy_rule.regional_default
  ]
}
