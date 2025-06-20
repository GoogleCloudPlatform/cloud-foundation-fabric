/**
 * Copyright 2024 Google LLC
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

output "chat_engine_ids" {
  description = "The ids of the chat engines created."
  value = {
    for k, v in google_discovery_engine_chat_engine.default
    : k => v.id
  }
}

output "chat_engines" {
  description = "The chat engines created."
  value       = google_discovery_engine_chat_engine.default
}

output "data_store_ids" {
  description = "The ids of the data stores created."
  value = {
    for k, v in google_discovery_engine_data_store.default
    : k => v.id
  }
}

output "data_stores" {
  description = "The data stores resources created."
  value       = google_discovery_engine_data_store.default
}

output "search_engine_ids" {
  description = "The ids of the search engines created."
  value = {
    for k, v in google_discovery_engine_search_engine.default
    : k => v.id
  }
}

output "search_engines" {
  description = "The search engines created."
  value       = google_discovery_engine_search_engine.default
}
