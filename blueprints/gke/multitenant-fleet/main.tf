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

# tfdoc:file:description Project and usage dataset.

locals {
  gke_nodes_sa_roles = [
    "autoscaling.metricsWriter",
    "logging.logWriter",
    "monitoring.viewer",
    "monitoring.metricWriter",
    "stackdriver.resourceMetadata.writer"
  ]
}

module "gke-project-0" {
  source            = "../../../modules/project"
  billing_account   = var.billing_account_id
  name              = var.project_id
  parent            = var.folder_id
  prefix            = var.prefix
  iam_by_principals = var.iam_by_principals
  labels            = var.labels
  iam = merge(var.iam, {
    "roles/gkehub.serviceAgent" = [
      module.gke-project-0.service_agents.fleet.iam_email
    ] }
  )
  iam_bindings_additive = {
    for r in local.gke_nodes_sa_roles : "gke-nodes-sa-${r}" => {
      member = module.gke-nodes-service-account.iam_email
      role   = "roles/${r}"
    }
  }
  services = concat(
    [
      "anthos.googleapis.com",
      "anthosconfigmanagement.googleapis.com",
      "cloudresourcemanager.googleapis.com",
      "container.googleapis.com",
      "dns.googleapis.com",
      "gkeconnect.googleapis.com",
      "gkehub.googleapis.com",
      "iam.googleapis.com",
      "multiclusteringress.googleapis.com",
      "multiclusterservicediscovery.googleapis.com",
      "stackdriver.googleapis.com",
      "trafficdirector.googleapis.com"
    ],
    var.project_services
  )
  shared_vpc_service_config = {
    attach       = true
    host_project = var.vpc_config.host_project_id
    service_agent_iam = merge({
      "roles/compute.networkUser" = [
        "cloudservices", "container-engine"
      ]
      "roles/container.hostServiceAgentUser" = [
        "container-engine"
      ]
      },
      !local.fleet_mcs_enabled ? {} : {
        "roles/multiclusterservicediscovery.serviceAgent" = ["mcsd"]
        "roles/compute.networkViewer" = [
          "serviceAccount:${var.prefix}-${var.project_id}.svc.id.goog[gke-mcs/gke-mcs-importer]"
        ]
    })
  }
  # specify project-level org policies here if you need them
}

module "gke-dataset-resource-usage" {
  source        = "../../../modules/bigquery-dataset"
  project_id    = module.gke-project-0.project_id
  id            = "gke_resource_usage"
  friendly_name = "GKE resource usage."
}

module "gke-nodes-service-account" {
  source     = "../../../modules/iam-service-account"
  project_id = module.gke-project-0.project_id
  name       = "gke-node-default"
}
