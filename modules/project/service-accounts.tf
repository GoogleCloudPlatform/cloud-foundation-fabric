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

# tfdoc:file:description Service identities and supporting resources.

locals {
  _service_agents_data = yamldecode(file("${path.module}/service-agents2.yaml"))
  # map of api => list of agents
  _service_agents_by_api = {
    for agent in local._service_agents_data :
    (agent.api) => agent...
  }
  # map of service agent name => agent details for this project
  _project_service_agents = merge(
    {
      cloudservices = {
        name         = "cloudservices"
        display_name = "Google APIs Service Agent"
        email        = "${local.project.number}@cloudservices.gserviceaccount.com"
        iam_email    = "serviceAccount:${local.project.number}@cloudservices.gserviceaccount.com"
        is_primary   = false
        role         = null
      }
    },
    [
      for api in setintersection(var.services, keys(local._service_agents_by_api)) : {
        for agent in local._service_agents_by_api[api] :
        (agent.name) => merge(agent, {
          email     = format(agent.identity, local.project.number)
          iam_email = "serviceAccount:${format(agent.identity, local.project.number)}"
        })
      }
    ]...
  )

  # service_accounts_robots = merge(
  #   {
  #     gke-mcs-importer = "${local.project.project_id}.svc.id.goog[gke-mcs/gke-mcs-importer]"
  #   }
  # )

  # list of APIs that with primary agents that should be created for
  # the current project, if the user requested it
  primary_service_agents = (
    var.service_agents_config.create_primary_agents
    ? [for agent in local._project_service_agents : agent.api if agent.is_primary]
    : []
  )
  # list of roles that should be granted to service agents for the
  # current project, if the user requested it
  service_agent_roles = (
    var.service_agents_config.grant_default_roles
    ? {
      for agent in local._project_service_agents :
      (agent.name) => {
        role      = agent.role
        iam_email = agent.iam_email
      }
      if agent.role != null
    }
    : {}
  )
  service_accounts_cmek_service_keys = merge([
    for service, keys in var.service_encryption_key_ids : {
      for key in keys :
      "${service}.${key}" => {
        service = service
        key     = key
      }
    }
  ]...)

  ## FIXME: do we want to keep the old aliases?
  _agent_aliases = {
    cloudrun         = "serverless-robot-prod"
    composer         = "cloudcomposer-accounts"
    compute          = "compute-system"
    container-engine = "container-engine-robot"
    dataproc         = "dataproc-accounts"
    cloudfunctions   = "gcf-admin-robot"
    dataflow         = "dataflow-service-producer-prod"
    gae-flex         = "gae-api-prod"
    gae-standard     = "gcp-gae-service"
    gke-mcs          = "multiclusterservicediscovery"
    monitoring       = "monitoring-notifications"
    storage          = "gs-project-accounts"
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

resource "google_project_service_identity" "default" {
  provider   = google-beta
  for_each   = toset(local.primary_service_agents)
  project    = local.project.project_id
  service    = each.key
  depends_on = [google_project_service.project_services]
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

resource "google_kms_crypto_key_iam_member" "service_identity_cmek" {
  for_each      = local.service_accounts_cmek_service_keys
  crypto_key_id = each.value.key
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = local._project_service_agents[lookup(local._agent_aliases, each.value.service, each.value.service)].iam_email
  depends_on = [
    google_project.project,
    google_project_service.project_services,
    google_project_service_identity.default,
    data.google_bigquery_default_service_account.bq_sa,
    data.google_project.project,
    data.google_storage_project_service_account.gcs_sa,
  ]
}

resource "google_project_default_service_accounts" "default_service_accounts" {
  count          = upper(var.default_service_account) == "KEEP" ? 0 : 1
  action         = upper(var.default_service_account)
  project        = local.project.project_id
  restore_policy = "REVERT_AND_IGNORE_FAILURE"
  depends_on     = [google_project_service.project_services]
}
