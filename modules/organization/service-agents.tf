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

# tfdoc:file:description Service agents supporting resources.

locals {
  _sa_raw = yamldecode(file("${path.module}/service-agents.yaml"))
  service_agents = {
    for agent in local._sa_raw :
    agent.name => {
      name         = agent.name
      api          = agent.api
      display_name = agent.display_name
      email        = templatestring(agent.identity, { organization_number = local.organization_id_numeric })
      iam_email    = "serviceAccount:${templatestring(agent.identity, { organization_number = local.organization_id_numeric })}"
    } if contains(var.service_agents_config.services, agent.api)
  }
  service_agents_ctx = {
    for k, v in local.service_agents :
    "$service_agents:${k}" => v.iam_email
  }
}

resource "google_organization_service_identity" "default" {
  provider     = google-beta
  for_each     = var.service_agents_config.create_agents ? local.service_agents : {}
  organization = local.organization_id_numeric
  service      = each.value.api
}
