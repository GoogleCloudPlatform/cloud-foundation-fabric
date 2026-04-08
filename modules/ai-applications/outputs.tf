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

output "chat_agent_id" {
  description = "The id of the (Dialogflow CX) chat agent."
  value       = try(google_dialogflow_cx_agent.default[0].id, null)
}

output "chat_agent" {
  description = "The (Dialogflow CX) chat agent object."
  value       = try(google_dialogflow_cx_agent.default[0], null)
}

output "chat_engine_id" {
  description = "The id of the chat engine."
  value       = try(google_discovery_engine_chat_engine.default[0].id, null)
}

output "chat_engine" {
  description = "The chat engine object."
  value       = try(google_discovery_engine_chat_engine.default[0], null)
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

output "search_engine_id" {
  description = "The id of the search engine."
  value       = try(google_discovery_engine_search_engine.default[0].id, null)
}

output "search_engine" {
  description = "The search engines object."
  value       = try(google_discovery_engine_search_engine.default[0], null)
}
