/**
 * Copyright 2022 Google LLC
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

locals {
  labels = merge(var.labels, { environment = "dev" })

  _gke_robot_sa      = "serviceAccount:${module.gke-project-0.service_accounts.robots.container-engine}"
  _cloud_services_sa = "serviceAccount:${module.gke-project-0.service_accounts.cloud_services}"

  logging_sinks = {
    for team, value in var.namespace_sinks : team => {
      type          = "logging"
      destination   = "projects/${value.project}/locations/global/buckets/${value.bucket}"
      filter        = "resource.labels.namespace_name=${team}"
      iam           = false
      unique_writer = true
      exclusions    = {}
    }
  }
}

module "gke-project-0" {
  source          = "../../../../modules/project"
  billing_account = var.billing_account.id
  name            = "dev-gke-clusters-0"
  parent          = var.folder_ids.gke-multitenant-dev
  prefix          = var.prefix
  labels          = local.labels
  services = [
    "anthosconfigmanagement.googleapis.com",
    "anthos.googleapis.com",
    "dns.googleapis.com",
    "gkeconnect.googleapis.com",
    "gkehub.googleapis.com",
    "stackdriver.googleapis.com",
    "container.googleapis.com"
  ]
  # add here any other service ids and keys for robot accounts which are needed
  # service_encryption_key_ids = {
  #   container = var.project_config.service_encryption_key_ids
  # }
  shared_vpc_service_config = {
    attach       = true
    host_project = var.host_project_ids.dev-spoke-0
    service_identity_iam = {
      "roles/compute.networkUser" = [
        "cloudservices", "container-engine"
      ]
      "roles/container.hostServiceAgentUser" = [
        "container-engine"
      ]
    }
  }

  # specify project-level org policies here if you need them
  # policy_boolean = {
  #   "constraints/compute.disableGuestAttributesAccess" = true
  # }
  # policy_list = {
  #   "constraints/compute.trustedImageProjects" = {
  #     inherit_from_parent = null
  #     suggested_value     = null
  #     status              = true
  #     values              = ["projects/fl01-prod-iac-core-0"]
  #   }
  # }
  iam = {
    "roles/container.clusterViewer" = var.cluster_viewers
  }

  # namespace_sinks
  logging_sinks = local.logging_sinks
}

# (dmarzi, jccb) to understand SA vs Scopes
# GKE Service Accounts - used in gke.tf file
module "gke-nodepool-sa" {
  source       = "git::https://github.com/terraform-google-modules/cloud-foundation-fabric//modules/iam-service-account?ref=v14.0.0"
  project_id   = module.gke-project-0.project_id
  name         = "gke-nodepool-sa"
  generate_key = false

  iam_project_roles = {
    "${module.gke-project-0.project_id}" = [
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
      "roles/stackdriver.resourceMetadata.writer",
      "roles/monitoring.viewer",
      "roles/storage.objectViewer"
    ]
  }
}

# Google Managed Prometheus 
module "gke-gmp-sa" {
  source       = "git::https://github.com/terraform-google-modules/cloud-foundation-fabric//modules/iam-service-account?ref=v14.0.0"
  project_id   = module.gke-project-0.project_id
  for_each     = var.namespace_sinks
  name         = "gke-gmp-${each.key}-sa"
  generate_key = false

  iam = {
    "roles/iam.workloadIdentityUser" = ["serviceAccount:${module.gke-project-0.project_id}.svc.id.goog[${each.key}/prometheus-robot]"]
  }
}

module "gke-dataset-resource-usage" {
  source        = "../../../../modules/bigquery-dataset"
  project_id    = module.gke-project-0.project_id
  id            = "gke_resource_usage"
  friendly_name = "GKE resource usage."
}
