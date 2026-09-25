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

output "agent_gateway" {
  description = "The Agent Gateway object."
  value       = google_network_services_agent_gateway.default
}

output "authz_extension_ids" {
  description = "The authorization extension ids, keyed by service."
  value = {
    for k, v in {
      iap = one(google_network_services_authz_extension.iap[*].id)
      model_armor = one(
        google_network_services_authz_extension.model_armor[*].id
      )
    } : k => v if v != null
  }
}

output "authz_policy_ids" {
  description = "The authorization policy ids, keyed by service."
  value = {
    for k, v in {
      iap = one(google_network_security_authz_policy.iap[*].id)
      model_armor = one(
        google_network_security_authz_policy.model_armor[*].id
      )
    } : k => v if v != null
  }
}

output "connectivity_template_id" {
  description = "The id of the agent connectivity template attached to the gateway."
  value       = local.connectivity_template_id
}

output "id" {
  description = "The Agent Gateway id."
  value       = google_network_services_agent_gateway.default.id
}
