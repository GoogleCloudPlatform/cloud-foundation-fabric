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
  value       = local.has_buckets ? local.buckets[0] : null
}

output "name" {
  description = "Bucket name (for single use)."
  value       = local.has_buckets ? local.buckets[0].name : null
}

output "url" {
  description = "Bucket URL (for single use)."
  value       = local.has_buckets ? local.buckets[0].url : null
}

output "buckets" {
  description = "Bucket resources."
  value       = local.buckets
}

output "names" {
  description = "Bucket names."
  value = (
    local.has_buckets
    ? zipmap(var.names, [for b in local.buckets : lookup(b, "name", null)])
    : {}
  )
}

output "urls" {
  description = "Bucket URLs."
  value = (
    local.has_buckets
    ? zipmap(var.names, [for b in local.buckets : b.url])
    : {}
  )
}

output "names_list" {
  description = "List of bucket names."
  value       = [for b in local.buckets : b.name]
}

output "urls_list" {
  description = "List of bucket URLs."
  value       = [for b in local.buckets : b.name]
}
