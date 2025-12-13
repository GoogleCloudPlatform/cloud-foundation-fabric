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
  # initial map of service agents by name, defining agent email
  _sa_0 = merge([
    for api in concat(local.services, ["cloudservices"]) : {
      for agent in lookup(local.service_agents_by_api, api, []) :
      (agent.name) => merge(agent, {
        email = (
          api == "cloudservices"
          ? (
            var.universe == null
            ? format(
              "%s@cloudservices.gserviceaccount.com",
              local.project.number
            )
            : format(
              "%s@cloudservices.%siam.gserviceaccount.com",
              local.project.number,
              local._u_domain
            )
          )
          : (
            var.universe == null || !startswith(api, "cloudkms.")
            ? templatestring(agent.identity, {
              project_number  = local.project.number
              universe_domain = local._u_domain
            })
            # universe uses partner KMS
            : format(
              "service-%s@gcp-sa-ekms.%siam.gserviceaccount.com",
              local.project.number,
              local._u_domain
            )
          )
        )
      })
    }
  ]...)
  # final map of service agents by name including JIT creation flag
  _sa = {
    for k, v in local._sa_0 : k => merge(v, {
      iam_email = "serviceAccount:${v.email}"
      create_jit = (
        v.api == null ? false : contains(local.available_services, v.api)
      )
      # skip identities which are unavailable in the defined universe
    }) if !contains(local._u_unavailable_si, k)
  }
  # map of name => agent for all known aliases
  _sa_aliases = merge(local._sa, flatten([
    for agent_name, agent in local._sa : [
      for alias in agent.aliases : { (alias) = agent }
    ]
  ])...)
  _u_domain = (
    var.universe == null ? "" : "${var.universe.prefix}-system."
  )
  _u_unavailable_si = try(
    var.universe.unavailable_service_identities, []
  )
  # aliased service agents, with unnecessary fields removed
  aliased_service_agents = {
    for k, v in local._sa_aliases : k => {
      api          = v.api
      display_name = v.display_name
      email        = v.email
      iam_email    = v.iam_email
      is_primary   = v.is_primary
      name         = v.name
      role         = v.role
    }
  }
  # service agents to create in this project
  primary_service_agents = [
    for agent in local._sa : agent.api if(
      # only create if user asked us to (which is the default)
      var.service_agents_config.create_primary_agents && (
        # only create if agent is primary and JIT flag is true
        (agent.is_primary && agent.create_jit)
        ||
        # or if universe configuration is forcing this agent to be created
        contains(
          try(var.universe.forced_jit_service_identities, []),
          coalesce(agent.api, "-")
        )
      )
    )
  ]
  # group service agents by api, cloudservices api is null
  service_agents_by_api = {
    for v in local._sa_raw : coalesce(v.api, "cloudservices") => v...
  }
  # IAM roles for service agents to create in this project
  service_agent_roles = {
    for agent in local._sa : (agent.name) => {
      role      = agent.role
      iam_email = agent.iam_email
      } if alltrue([
        var.service_agents_config.grant_default_roles,
        agent.role != null,
        !agent.skip_iam
    ])
  }
  services = [
    for s in distinct(concat(
      local.available_services,
      try(var.project_reuse.attributes.services_enabled, [])
    )) : s if !contains(local._u_unavailable_si, s)
  ]
}

data "google_storage_project_service_account" "gcs_sa" {
  count      = contains(var.services, "storage.googleapis.com") ? 1 : 0
  project    = local.project.project_id
  depends_on = [google_project_service.project_services]
}

data "google_bigquery_default_service_account" "bq_sa" {
  count      = contains(var.services, "bigquery.googleapis.com") ? 1 : 0
  project    = local.project.project_id
  depends_on = [google_project_service.project_services]
}

data "google_logging_project_settings" "logging_sa" {
  count      = contains(var.services, "logging.googleapis.com") ? 1 : 0
  project    = local.project.project_id
  depends_on = [google_project_service.project_services]
}

moved {
  from = google_project_service_identity.jit_si
  to   = google_project_service_identity.default
}

moved {
  from = google_project_service_identity.servicenetworking[0]
  to   = google_project_service_identity.default["servicenetworking.googleapis.com"]
}

resource "google_project_service_identity" "default" {
  provider   = google-beta
  for_each   = toset(local.primary_service_agents)
  project    = local.project.project_id
  service    = each.key
  depends_on = [google_project_service.project_services]
}

moved {
  from = google_project_iam_member.servicenetworking[0]
  to   = google_project_iam_member.service_agents["service-networking"]
}

resource "google_project_iam_member" "service_agents" {
  for_each = local.service_agent_roles
  project  = local.project.project_id
  role     = each.value.role
  member   = each.value.iam_email
  depends_on = [
    google_project_service.project_services,
    google_project_service_identity.default
  ]
}

resource "google_project_default_service_accounts" "default_service_accounts" {
  count          = upper(var.default_service_account) == "KEEP" ? 0 : 1
  action         = upper(var.default_service_account)
  project        = local.project.project_id
  restore_policy = "REVERT_AND_IGNORE_FAILURE"
  depends_on     = [google_project_service.project_services]
}
