/**
 * Copyright 2020 Google LLC
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

output "bucket_name" {
  description = "Bucket name."
  value       = local.bucket
}

output "function_name" {
  description = "Cloud function name."
  value       = google_cloudfunctions_function.function.name
}

output "service_account_email" {
  description = "Service account email."
  value       = google_service_account.service_account.email
}

output "topic_id" {
  description = "PubSub topic id."
  value       = google_pubsub_topic.topic.id
}
