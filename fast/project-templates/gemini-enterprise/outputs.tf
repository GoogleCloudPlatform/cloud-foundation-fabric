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

output "cmek_key_id" {
  description = "Cloud KMS crypto key ID used for Discovery Engine CMEK encryption."
  value       = local.effective_kms_key
}

output "data_store_ids" {
  description = "Foundational Discovery Engine data store IDs created in the project."
  value       = module.gemini-enterprise-prod.data_store_ids
}

output "gcs_corpus_bucket" {
  description = "Cloud Storage bucket backing the periodic GCS knowledge connector."
  value       = try(google_storage_bucket.knowledge_corpus[0].name, null)
}

output "production_app_id" {
  description = "Primary Production Workforce Gemini Enterprise engine resource ID."
  value       = module.gemini-enterprise-prod.search_engine_id
}

output "production_web_app_url" {
  description = "Web App URL for the Primary Production Workforce Gemini Enterprise app."
  value       = "https://vertexaisearch.cloud.google.com/home/cid/${module.gemini-enterprise-prod.widget_config.widget_config_id}"
}

output "validation_app_id" {
  description = "Restricted Connector Validation Gemini Enterprise engine resource ID."
  value       = module.gemini-enterprise-validation.search_engine_id
}

output "validation_web_app_url" {
  description = "Web App URL for the Restricted Connector Validation Gemini Enterprise app."
  value       = "https://vertexaisearch.cloud.google.com/home/cid/${module.gemini-enterprise-validation.widget_config.widget_config_id}"
}
