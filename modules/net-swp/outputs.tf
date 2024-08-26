/**
 * Copyright 2022 Google LLC
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

output "gateway" {
  description = "The gateway resource."
  value       = google_network_services_gateway.default
}

output "gateway_security_policy" {
  description = "The gateway security policy resource."
  value       = google_network_services_gateway.default.gateway_security_policy
}

output "id" {
  description = "ID of the gateway resource."
  value       = google_network_services_gateway.default.id
}

output "service_attachment" {
  description = "ID of the service attachment resource, if created."
  value       = var.service_attachment == null ? "" : google_compute_service_attachment.default[0].id
}
