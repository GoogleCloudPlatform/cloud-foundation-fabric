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

output "id" {
  description = "Fully qualified firewall policy id."
  value = (
    local.use_hierarchical
    ? google_compute_firewall_policy.hierarchical[0].id
    : (
      local.use_regional
      ? google_compute_region_network_firewall_policy.net-regional[0].id
      : google_compute_network_firewall_policy.net-global[0].id
    )
  )
}
