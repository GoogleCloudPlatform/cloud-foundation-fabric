/**
 * Copyright 2025 Google LLC
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

output "composer_environment_name" {
  description = "The name of the Composer environment."
  value       = var.composer_config.environment_name
}

output "composer_project_id" {
  description = "The project ID where the Composer environment is located."
  value       = var.composer_config.project_id
}

output "dp_processing_service_account" {
  description = "Service account for data processing."
  value       = var.dp_processing_service_account
}

output "landing_gcs_bucket" {
  description = "The name of the landing GCS bucket."
  value       = module.land-cs-0.name
}

output "location" {
  description = "The location/region used for resources."
  value       = var.location
}

resource "local_file" "composer_variables" {
  content = templatefile("composer/variables.tf.tpl", {
    dp_project                    = var.project_id
    location                      = var.location
    dp_processing_service_account = var.dp_processing_service_account
    land_gcs                      = module.land-cs-0.bucket.name
    land_bq_dataset               = module.land-bq-0.dataset_id
    curated_bq_dataset            = module.cur-bq-0.dataset_id
    exposure_bq_dataset           = var.authorized_dataset_on_curated
  })
  filename = "${path.module}/composer/variables.json"
}
