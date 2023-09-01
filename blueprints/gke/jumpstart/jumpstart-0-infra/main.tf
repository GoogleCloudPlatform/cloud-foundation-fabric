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
  create_cluster = var.create_cluster != null || local.create_vpc
  create_vpc = (
    !local.use_shared_vpc && (
      var.create_vpc != null || var.create_project != null
    )
  )
  fleet_project = (
    var.fleet_project_id == null
    ? {
      project_id = var.project_id
      number     = module.project.number
    }
    : {
      project_id = var.fleet_project_id
      number     = module.fleet-project.0.number
    }
  )
  use_shared_vpc = (
    try(var.create_project.shared_vpc_host, null) != null
  )
}

module "project" {
  source          = "../../../../modules/project"
  parent          = try(var.create_project.parent, null)
  billing_account = try(var.create_project.billing_account, null)
  name            = var.project_id
  project_create  = var.create_project != null
  services = compact([
    "anthos.googleapis.com",
    var.create_registry ? "artifactregistry.googleapis.com" : null,
    "cloudresourcemanager.googleapis.com",
    "connectgateway.googleapis.com",
    "container.googleapis.com",
    "gkeconnect.googleapis.com",
    "gkehub.googleapis.com",
    "stackdriver.googleapis.com"
  ])
  shared_vpc_service_config = !local.use_shared_vpc ? null : {
    attach       = true
    host_project = var.create_project.shared_vpc_host
    # grant required roles on the host project to service identities
    service_identity_iam = {
      "roles/compute.networkUser" = [
        "cloudservices", "container-engine"
      ]
      "roles/container.hostServiceAgentUser" = [
        "container-engine"
      ]
    }
  }
  iam_bindings_additive = merge(
    # allow GKE fleet service identity to manage clusters in this project
    {
      gkehub-robot = {
        role = "roles/gkehub.serviceAgent"
        member = (
          var.fleet_project_id == null
          ? "serviceAccount:${module.project.service_accounts.robots.gkehub}"
          : "serviceAccount:${module.fleet-project.0.service_accounts.robots.gkehub}"
        )
      }
    },
    # grant required roles to GKE node service account
    {
      for r in local.cluster_sa_roles : "gke-sa-${r}" => {
        role   = r
        member = "serviceAccount:${local.cluster_sa}"
      }
    }
  )
}

module "vpc" {
  source     = "../../../../modules/net-vpc"
  count      = local.create_vpc ? 1 : 0
  project_id = module.project.project_id
  name = coalesce(
    try(var.create_vpc.name, null), var.prefix
  )
  subnets = [{
    name = coalesce(
      try(var.create_vpc.subnet_name, null), "${var.prefix}-default"
    )
    region = var.region
    ip_cidr_range = try(
      var.create_vpc.primary_range_nodes, "10.0.0.0/24"
    )
    secondary_ip_ranges = {
      pods = try(
        var.create_vpc.secondary_range_pods, "10.16.0.0/20"
      )
      services = try(
        var.create_vpc.secondary_range_services, "10.32.0.0/24"
      )
    }
  }]
}

module "fleet-project" {
  source         = "../../../../modules/project"
  count          = var.fleet_project_id == null ? 0 : 1
  name           = var.fleet_project_id
  project_create = false
}

module "fleet" {
  source     = "../../../../modules/gke-hub"
  project_id = local.fleet_project.project_id
  clusters = {
    (var.cluster_name) = (
      var.create_cluster != null
      ? module.cluster.0.id
      : "projects/${var.project_id}/locations/${var.region}/clusters/${var.cluster_name}"
    )
  }
}

module "registry" {
  source     = "../../../../modules/artifact-registry"
  count      = var.create_registry ? 1 : 0
  project_id = module.project.project_id
  location   = var.region
  name       = var.prefix
  format     = { docker = {} }
  mode       = { remote = true }
}
