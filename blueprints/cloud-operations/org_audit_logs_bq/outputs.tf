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

output "org_id" {
  description = "Organization Id."
  value       = var.org_id
}

output "org_log_service_account" {
  description = "Serice account used by the org sink to write to the BigQuery table."
  value       = google_logging_organization_sink.audit_log_org_sink.writer_identity
}

output "org_log_sink_id" {
  description = "Organization level log sink Id."
  value       = google_logging_organization_sink.audit_log_org_sink.id
}

output "dataset_id" {
  description = "Dataset Id where logs are routed."
  value       = var.dataset_id
}

output "project_id" {
  description = "Project containing the BigQuery dataset where logs are routed."
  value       = module.project.project_id
}