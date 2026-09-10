# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

output "eventarc_trigger_ids" {
  description = "Map of Eventarc trigger IDs keyed by trigger name."
  value       = { for k, v in google_eventarc_trigger.default : k => v.id }
}

output "eventarc_triggers" {
  description = "Eventarc trigger resources."
  value       = google_eventarc_trigger.default
}

output "id" {
  description = "The workflow ID."
  value       = google_workflows_workflow.default.id
  depends_on = [
    google_project_iam_member.service_account,
    google_project_iam_member.default
  ]
}

output "name" {
  description = "The workflow name."
  value       = google_workflows_workflow.default.name
}

output "revision_id" {
  description = "The revision ID of the workflow."
  value       = google_workflows_workflow.default.revision_id
}

output "scheduler_job_ids" {
  description = "Map of Cloud Scheduler job IDs keyed by job name."
  value       = { for k, v in google_cloud_scheduler_job.default : k => v.id }
}

output "scheduler_jobs" {
  description = "Cloud Scheduler job resources."
  value       = google_cloud_scheduler_job.default
}

output "service_account" {
  description = "The service account email used for execution."
  value       = local.service_account
}

output "service_account_email" {
  description = "The email of the created service account."
  value       = try(google_service_account.service_account[0].email, null)
}

output "task_queue_ids" {
  description = "Map of Cloud Tasks queue IDs keyed by queue name."
  value       = { for k, v in google_cloud_tasks_queue.default : k => v.id }
}

output "task_queues" {
  description = "Cloud Tasks queue resources."
  value       = google_cloud_tasks_queue.default
}

output "workflow" {
  description = "The workflow resource."
  value       = google_workflows_workflow.default
}
