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

# tfdoc:file:description Module outputs.

output "service_accounts" {
  description = "Service account resources."
  value       = module.service-accounts
}

output "gcs" {
  description = "GCS bucket resources."
  value       = module.gcs
}

output "pubsub" {
  description = "Pub/Sub topic resources."
  value       = module.pubsub
}

output "bigquery" {
  description = "BigQuery dataset resources."
  value       = module.bigquery
}

output "secret_manager" {
  description = "Secret Manager resources."
  value       = module.secret-manager
}

output "artifact_registry" {
  description = "Artifact Registry resources."
  value       = module.artifact-registry
}

output "compute_vm" {
  description = "Compute VM resources."
  value       = module.compute-vm
}

output "cloudsql" {
  description = "Cloud SQL instance resources."
  value       = module.cloudsql
}

output "net_lb_int" {
  description = "Internal TCP/UDP load balancer resources."
  value       = module.net-lb-int
}

output "net_lb_app_int" {
  description = "Internal application load balancer resources."
  value       = module.net-lb-app-int
}
