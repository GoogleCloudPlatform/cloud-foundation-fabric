
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

output "automation_ids" {
  description = "Automation ids."
  value       = values(google_clouddeploy_automation.default)[*].id
}

output "deploy_policy_ids" {
  description = "Deploy Policy ids."
  value       = values(google_clouddeploy_deploy_policy.default)[*].id
}

output "pipeline_id" {
  description = "Delivery pipeline id."
  value       = google_clouddeploy_delivery_pipeline.default.id
}

output "target_ids" {
  description = "Target ids."
  value       = values(google_clouddeploy_target.default)[*].id
}

