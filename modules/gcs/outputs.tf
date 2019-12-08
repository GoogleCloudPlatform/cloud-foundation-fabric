/**
 * Copyright 2018 Google LLC
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

output "bucket" {
  description = "Bucket resource (for single use)."
  value       = length(var.names) > 0 ? google_storage_bucket.buckets[var.names[0]] : null
}

output "name" {
  description = "Bucket name (for single use)."
  value       = length(var.names) > 0 ? google_storage_bucket.buckets[var.names[0]].name : null
}

output "url" {
  description = "Bucket URL (for single use)."
  value       = length(var.names) > 0 ? google_storage_bucket.buckets[var.names[0]].url : null
}

output "buckets" {
  description = "Bucket resources."
  value       = google_storage_bucket.buckets
}

output "names" {
  description = "Bucket names."
  value       = { for name in var.names : name => google_storage_bucket.buckets[name].name }
}

output "urls" {
  description = "Bucket URLs."
  value       = { for name in var.names : name => google_storage_bucket.buckets[name].url }
}

output "names_list" {
  description = "List of bucket names."
  value       = [for bucket in local.buckets_list : bucket.name]
}

output "urls_list" {
  description = "List of bucket URLs."
  value       = [for bucket in local.buckets_list : bucket.url]
}
