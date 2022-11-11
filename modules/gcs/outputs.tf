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

output "as_logging_destination" {
  description = "Parameters to use this bucket as a log sink destination."
  value = {
    type   = "storage"
    target = "${local.prefix}${lower(var.name)}"
  }
  depends_on = [
    google_storage_bucket.bucket,
    google_storage_bucket_iam_binding.bindings
  ]
}

output "bucket" {
  description = "Bucket resource."
  value       = google_storage_bucket.bucket
}

output "name" {
  description = "Bucket name."
  value       = "${local.prefix}${lower(var.name)}"
  depends_on = [
    google_storage_bucket.bucket,
    google_storage_bucket_iam_binding.bindings
  ]
}

output "notification" {
  description = "GCS Notification self link."
  value       = local.notification ? google_storage_notification.notification[0].self_link : null
}

output "topic" {
  description = "Topic ID used by GCS."
  value       = local.notification ? google_pubsub_topic.topic[0].id : null
}

output "url" {
  description = "Bucket URL."
  value       = google_storage_bucket.bucket.url
}
