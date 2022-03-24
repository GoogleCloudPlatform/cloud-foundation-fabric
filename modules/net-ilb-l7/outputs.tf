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

output "health_checks" {
  description = "Health-check resources."
  value       = try(google_compute_region_health_check.health_check, [])
}

output "backend_services" {
  description = "Backend service resources."
  value = {
    group = try(google_compute_region_backend_service.backend_service, [])
  }
}

output "url_map" {
  description = "The url-map."
  value       = google_compute_region_url_map.url_map
}

output "ssl_certificates" {
  description = "The SSL certificate."
  value       = try(google_compute_ssl_certificate.certificates, null)
}

output "ip_address" {
  description = "The reserved IP address."
  value       = try(google_compute_address.static_ip, null)
}

output "target_proxy" {
  description = "The target proxy."
  value = try(
    google_compute_region_target_https_proxy.https,
    google_compute_region_target_http_proxy.http
  )
}

output "forwarding_rule" {
  description = "The forwarding rule."
  value       = google_compute_forwarding_rule.forwarding_rule
}
