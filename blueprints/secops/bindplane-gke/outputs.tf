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

output "bindplane_hostname" {
  description = "BindPlane OP Management console hostname."
  value       = "https://${var.dns_config.hostname}.${var.dns_config.domain}"
}

output "ca_cert" {
  description = "TLS CA certificate."
  value       = try(tls_self_signed_cert.ca_cert.0.cert_pem, null)
}

output "cluster_ca_certificate" {
  description = "GKE CA Certificate."
  value       = module.bindplane-cluster.ca_certificate
}

output "fleet_host" {
  description = "GKE Fleet host."
  value       = local.fleet_host
}

output "lb_ip_address" {
  description = "Ingress LB address."
  value       = module.addresses.internal_addresses["ingress"].address
}
