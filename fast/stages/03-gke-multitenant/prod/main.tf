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
  labels = merge(var.labels, { environment = var.environment })
  
  _gke_robot_sas      = [
    "serviceAccount:${module.gke-project-0.service_accounts.robots.container-engine}",
    "serviceAccount:${module.gke-project-1.service_accounts.robots.container-engine}"
  ]
  _cloud_services_sas = [
    "serviceAccount:${module.gke-project-0.service_accounts.cloud_services}",
    "serviceAccount:${module.gke-project-1.service_accounts.cloud_services}"
  ]
  host_project_cloud_services_bindings = [ for member in local._cloud_services_sas :
    {role = "roles/compute.networkUser", member = member }
  ]
  host_project_gke_robot_bindings = [ for member in local._gke_robot_sas : 
    [{role = "roles/container.hostServiceAgentUser", member = member },
    {role = "roles/compute.networkUser", member = member }]
  ]
}

module "gke-project-0" {
  source          = "../../../../modules/project"
  billing_account = var.billing_account_id
  name            = "${var.environment}-gke-clusters-0"
  parent          = var.folder_id
  prefix          = var.prefix
  labels          = local.labels
  services = [
    "container.googleapis.com",
    "dns.googleapis.com",
    "stackdriver.googleapis.com",
    # uncomment if you need Multi-cluster Ingress / Gateway API
    # "gkehub.googleapis.com",
    # "multiclusterservicediscovery.googleapis.com",
    # "multiclusteringress.googleapis.com",
    # "trafficdirector.googleapis.com"
  ]
  # add here any other service ids and keys for robot accounts which are needed
  # service_encryption_key_ids = {
  #   container = var.project_config.service_encryption_key_ids
  # }
  shared_vpc_service_config = {
    attach       = true
    host_project = var.vpc_host_project
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

module "gke-project-1" {
  source          = "../../../../modules/project"
  billing_account = var.billing_account_id
  name            = "${var.environment}-gke-clusters-1"
  parent          = var.folder_id
  prefix          = var.prefix
  labels          = local.labels
  services = [
    "container.googleapis.com",
    "dns.googleapis.com",
    "stackdriver.googleapis.com",
    # uncomment if you need Multi-cluster Ingress / Gateway API
    # "gkehub.googleapis.com",
    # "multiclusterservicediscovery.googleapis.com",
    # "multiclusteringress.googleapis.com",
    # "trafficdirector.googleapis.com"
  ]
  # add here any other service ids and keys for robot accounts which are needed
  # service_encryption_key_ids = {
  #   container = var.project_config.service_encryption_key_ids
  # }
  shared_vpc_service_config = {
    attach       = true
    host_project = var.vpc_host_project
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
  id            = "resource_usage"
  friendly_name = "GKE resource usage."
}

resource "google_project_iam_member" "host_project_gke_robot_bindings" {
  for_each = { for i, v in flatten(local.host_project_gke_robot_bindings) : i => v }
  project  = var.vpc_host_project
  role     = each.value.role
  member   = each.value.member
}
resource "google_project_iam_member" "host_project_cloud_services_bindings" {
  for_each = { for i, v in local.host_project_cloud_services_bindings : i => v }
  project  = var.vpc_host_project
  role     = each.value.role
  member   = each.value.member
}
