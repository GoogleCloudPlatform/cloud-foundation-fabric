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
  services = distinct(concat(
    local.available_services, try(var.project_reuse.project_attributes.services_enabled, [])
  ))
  _service_agents_data = yamldecode(file("${path.module}/service-agents.yaml"))
  # map of api => list of agents
  _service_agents_by_api = {
    for agent in local._service_agents_data :
    coalesce(agent.api, "cloudservices") => agent... # cloudservices api is null
  }
  _universe_domain = (
    var.universe == null
    ? ""
    : "${var.universe.prefix}-system."
  )
  # map of service agent name => agent details for this project
  _project_service_agents_0 = merge([
    for api in concat(local.services, ["cloudservices"]) : {
      for agent in lookup(local._service_agents_by_api, api, []) :
      (agent.name) => merge(agent, {
        email = (
          # If universe variable is set, enfore the use of the service-PROJECT_NUMBER@gcp-sa-ekms.UNVIVERSE-system.iam.gserviceaccount.com
          # instead of service-PROJECT_NUMBER@gcp-sa-kms.UNVIVERSE-system.iam.gserviceaccount.com
          # as in the TPC universes, the partner KMS is enforced by design
          var.universe != null && api == "cloudkms.googleapis.com"
          ? format("service-%s@gcp-sa-ekms.%siam.gserviceaccount.com", local.project.number, local._universe_domain)
          : (
            var.universe == null || api != "cloudservices"
            ? templatestring(agent.identity, { project_number = local.project.number, universe_domain = local._universe_domain })
            : format("%s@cloudservices.%siam.gserviceaccount.com", local.project.number, local._universe_domain)
          )
        )
      })
    }
  ]...)
  _project_service_agents = {
    for k, v in local._project_service_agents_0 :
    k => merge(v, {
      iam_email  = "serviceAccount:${v.email}"
      create_jit = v.api == null ? false : contains(local.available_services, v.api)
    })
  }
  # list of APIs with primary agents that should be created for the
  # current project, if the user requested it
  primary_service_agents = [
    for agent in local._project_service_agents : agent.api if(
      agent.is_primary &&
      var.service_agents_config.create_primary_agents &&
      agent.create_jit
    )
  ]
  # list of roles that should be granted to service agents for the
  # current project, if the user requested it
  service_agent_roles = {
    for agent in local._project_service_agents :
    (agent.name) => {
      role      = agent.role
      iam_email = agent.iam_email
    }
    if alltrue([
      var.service_agents_config.grant_default_roles,
      agent.role != null,
      # FIXME: granting roles to the non-primary agents listed below
      # currently fails, possibly because the agents doesn't exist
      # after API activation. As a workaround, automatic role
      # assignment for these agents is disabled.
      !contains([
        "apigateway", "apigateway-mgmt", "bigqueryspark", "bigquerytardis",
        "firebase", "krmapihosting", "krmapihosting-dataplane", "logging",
        "networkactions", "prod-bigqueryomni", "scc-notification", "securitycenter",
      ], agent.name)
    ])
  }
  # map of name->agent including all known aliases
  _aliased_service_agents = merge(
    local._project_service_agents,
    flatten([
      for agent_name, agent in local._project_service_agents : [
        for alias in agent.aliases :
        { (alias) = agent }
      ]
    ])...
  )
  # same as _aliased_service_agents with unneeded fields removed
  aliased_service_agents = {
    for k, v in local._aliased_service_agents :
    k => {
      api          = v.api
      display_name = v.display_name
      email        = v.email
      iam_email    = v.iam_email
      is_primary   = v.is_primary
      role         = v.role
    }
  }
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
