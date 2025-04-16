/**
 * Copyright 2024 Google LLC
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

output "external_gateway" {
  description = "External VPN gateway resource."
  value       = module.gcp_vpn.external_gateway
}

output "gateway" {
  description = "VPN gateway resource (only if auto-created)."
  value       = module.gcp_vpn.gateway
}

output "id" {
  description = "Fully qualified VPN gateway id."
  value       = module.gcp_vpn.id
}
