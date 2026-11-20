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

output "id" {
  description = "The Agent Registry URI for the default location, in the format used by Agent Gateway 'registries'."
  value       = "${local.uri_prefix}/locations/${local.location}"
  depends_on  = [google_agent_registry_service.default]
}

output "registry_resource_ids" {
  description = "The generated ids of the registered agents, endpoints and MCP servers, keyed by service ID."
  value = {
    for k, v in google_agent_registry_service.default :
    k => basename(v.registry_resource)
  }
}

output "registry_resources" {
  description = "The resource names of the registered agents, endpoints and MCP servers, keyed by service ID."
  value = {
    for k, v in google_agent_registry_service.default :
    k => v.registry_resource
  }
}

output "registry_uris" {
  description = "The Agent Registry URIs for the default location and the service locations, keyed by location."
  value = {
    for l in distinct(concat(
      [local.location], [for v in local.services : v.location]
    )) : l => "${local.uri_prefix}/locations/${l}"
  }
  depends_on = [google_agent_registry_service.default]
}

output "service_names" {
  description = "The resource names of the registered services, keyed by service ID."
  value = {
    for k, v in google_agent_registry_service.default : k => v.name
  }
}

output "services" {
  description = "Service resources, keyed by service ID."
  value       = google_agent_registry_service.default
}
