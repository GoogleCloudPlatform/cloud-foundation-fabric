/**
 * Copyright 2023 Google LLC
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
  create_vpc = !local.use_shared_vpc && var.create_config.vpc != null
  fleet_project = (
    var.fleet_config.project_id == null
    ? {
      project_id = var.project_id
      number     = module.project.number
    }
    : {
      project_id = var.fleet_config.project_id
      number     = module.fleet-project.0.number
    }
  )
  use_shared_vpc = (
    try(var.create_config.project.shared_vpc_host, null) != null
  )
}

module "project" {
  source          = "../../../modules/project"
  parent          = try(var.create_config.project.parent, null)
  billing_account = try(var.create_config.project.billing_account, null)
  name            = var.project_id
  project_create  = var.create_config.project != null
  services = concat(
    [
      "anthos.googleapis.com",
      "cloudresourcemanager.googleapis.com",
      "connectgateway.googleapis.com",
      "container.googleapis.com",
      "gkeconnect.googleapis.com",
      "gkehub.googleapis.com",
      "stackdriver.googleapis.com"
    ],
    var.create_config.remote_registry ? ["artifactregistry.googleapis.com"] : []
  )
  shared_vpc_service_config = !local.use_shared_vpc ? null : {
    attach       = true
    host_project = var.create_config.project.shared_vpc_host
    service_identity_iam = {
      "roles/compute.networkUser" = [
        "cloudservices", "container-engine"
      ]
      "roles/container.hostServiceAgentUser" = [
        "container-engine"
      ]
    }
  }
  iam = {
    "roles/gkehub.serviceAgent" = [
      var.fleet_config.project_id == null
      ? "serviceAccount:${module.project.service_accounts.robots.gkehub}"
      : "serviceAccount:service-${module.fleet-project.0.number}@gcp-sa-gkehub.iam.gserviceaccount.com"
    ]
  }
}

module "vpc" {
  source     = "../../../modules/net-vpc"
  count      = local.create_vpc ? 1 : 0
  project_id = module.project.project_id
  name       = var.prefix
  subnets = [
    {
      ip_cidr_range = var.create_config.vpc.primary_range_nodes
      name          = "${var.prefix}-default"
      region        = var.region
      secondary_ip_ranges = {
        pods     = var.create_config.vpc.secondary_range_pods
        services = var.create_config.vpc.secondary_range_services
      }
    }
  ]
}

module "fleet-project" {
  source         = "../../../modules/project"
  count          = var.fleet_config.project_id == null ? 0 : 1
  name           = var.fleet_config.project_id
  project_create = false
}

module "fleet" {
  source     = "../../../modules/gke-hub"
  project_id = local.fleet_project.project_id
  clusters = {
    (var.cluster_name) = (
      var.create_config.cluster != null
      ? module.cluster.0.id
      : "projects/${var.project_id}/locations/${var.region}/clusters/${var.cluster_name}"
    )
  }
}

module "registry" {
  source     = "../../../modules/artifact-registry"
  count      = var.create_config.remote_registry ? 1 : 0
  project_id = module.project.project_id
  location   = var.region
  name       = var.prefix
  format     = { docker = {} }
  mode       = { remote = true }
}
