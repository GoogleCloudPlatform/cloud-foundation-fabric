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
}

module "gke-project-0" {
  source          = "../../../../modules/project"
  billing_account = var.billing_account.id
  name            = "dev-gke-clusters-0"
  parent          = var.folder_ids.gke-dev
  prefix          = var.prefix
  group_iam       = var.group_iam
  labels          = local.labels
  # TODO: depend GKE hub services on GKE hub variable/activation
  services = [
    # "anthosconfigmanagement.googleapis.com",
    # "anthos.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "container.googleapis.com",
    "dns.googleapis.com",
    # "gkeconnect.googleapis.com",
    # "gkehub.googleapis.com",
    "iam.googleapis.com",
    # "multiclusteringress.googleapis.com",
    # "multiclusterservicediscovery.googleapis.com",
    "stackdriver.googleapis.com",
    # "trafficdirector.googleapis.com"
  ]
  shared_vpc_service_config = {
    attach       = true
    host_project = var.host_project_ids.dev-spoke-0
    service_identity_iam = merge({
      "roles/compute.networkUser" = [
        "cloudservices", "container-engine"
      ]
      "roles/container.hostServiceAgentUser" = [
        "container-engine"
      ]
      },
      !local.fleet_mcs_enabled ? {} : {
        "roles/multiclusterservicediscovery.serviceAgent" = ["gke-mcs"]
        "roles/compute.networkViewer"                     = ["gke-mcs-importer"]
    })
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
}

module "gke-dataset-resource-usage" {
  source        = "../../../../modules/bigquery-dataset"
  project_id    = module.gke-project-0.project_id
  id            = "gke_resource_usage"
  friendly_name = "GKE resource usage."
}
