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

output "acl_config" {
  description = "Location-level ACL configuration resource."
  value       = one(google_discovery_engine_acl_config.default[*])
}

output "acl_config_id" {
  description = "Location-level ACL configuration resource ID."
  value       = try(google_discovery_engine_acl_config.default[0].id, null)
}

output "app_iam_principals" {
  description = "Deduplicated project-eligible IAM principals granted roles across any Gemini Enterprise app."
  value       = local.app_iam_principals
}

output "assistant_ids" {
  description = "Managed assistant resource IDs, keyed by app key."
  value = {
    for k, v in google_discovery_engine_assistant.default : k => v.id
  }
}

output "assistants" {
  description = "Managed assistant resources, keyed by app key."
  value       = google_discovery_engine_assistant.default
}

output "cmek_config" {
  description = "Location-level CMEK configuration resource."
  value       = one(google_discovery_engine_cmek_config.default[*])
}

output "cmek_config_id" {
  description = "Location-level CMEK configuration resource ID."
  value       = try(google_discovery_engine_cmek_config.default[0].id, null)
}

output "data_connector_ids" {
  description = "SaaS data connector resource IDs, keyed by connector key."
  value = {
    for k, v in google_discovery_engine_data_connector.default : k => v.id
  }
}

output "data_connectors" {
  description = "SaaS data connector resources, keyed by connector key."
  value       = google_discovery_engine_data_connector.default
}

output "data_store_ids" {
  description = "Native data store resource IDs, keyed by store key."
  value = {
    for k, v in google_discovery_engine_data_store.default : k => v.id
  }
  depends_on = [
    google_discovery_engine_schema.default,
  ]
}

output "data_stores" {
  description = "Native data store resources, keyed by store key."
  value       = google_discovery_engine_data_store.default
  depends_on = [
    google_discovery_engine_schema.default,
  ]
}

output "engine_ids" {
  description = "Created Gemini Enterprise search engine resource IDs, keyed by app key."
  value = {
    for k, v in google_discovery_engine_search_engine.default : k => v.id
  }
  depends_on = [
    google_discovery_engine_assistant.default,
    google_discovery_engine_search_engine_iam_binding.authoritative,
    google_discovery_engine_search_engine_iam_binding.bindings,
    google_discovery_engine_search_engine_iam_member.bindings,
    google_discovery_engine_widget_config.default,
    terraform_data.app_agent_gateway_patch,
    terraform_data.app_data_stores,
    terraform_data.mcp_action_config,
  ]
}

output "engines" {
  description = "Created Gemini Enterprise search engine resources, keyed by app key."
  value       = google_discovery_engine_search_engine.default
  depends_on = [
    google_discovery_engine_assistant.default,
    google_discovery_engine_search_engine_iam_binding.authoritative,
    google_discovery_engine_search_engine_iam_binding.bindings,
    google_discovery_engine_search_engine_iam_member.bindings,
    google_discovery_engine_widget_config.default,
    terraform_data.app_agent_gateway_patch,
    terraform_data.app_data_stores,
    terraform_data.mcp_action_config,
  ]
}

output "mcp_connector_ids" {
  description = "Custom MCP data connector resource IDs, keyed by connector key (or '<connector>/<app>' when expanded across multiple gateway-bound apps)."
  value = {
    for k, v in google_discovery_engine_data_connector.mcp : k => v.id
  }
  depends_on = [
    terraform_data.mcp_action_config,
  ]
}

output "mcp_connectors" {
  description = "Custom MCP data connector resources, keyed by connector key (or '<connector>/<app>' when expanded across multiple gateway-bound apps)."
  value       = google_discovery_engine_data_connector.mcp
  depends_on = [
    terraform_data.mcp_action_config,
  ]
}

output "user_store" {
  description = "Location-level default user store resource."
  value       = one(google_discovery_engine_user_store.default[*])
}

output "user_store_id" {
  description = "Location-level default user store resource ID."
  value       = try(google_discovery_engine_user_store.default[0].id, null)
}

output "widget_config_ids" {
  description = "Search widget configuration resource IDs, keyed by app key."
  value = {
    for k, v in google_discovery_engine_widget_config.default : k => v.id
  }
}

output "widget_configs" {
  description = "Search widget configuration resources, keyed by app key."
  value       = google_discovery_engine_widget_config.default
}
