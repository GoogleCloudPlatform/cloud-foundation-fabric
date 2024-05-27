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

locals {
  cluster_create = var.cluster_create != null || local.vpc_create
  create_nat     = local.vpc_create && try(var.vpc_create.enable_cloud_nat, false) == true
  vpc_create = (
    !local.use_shared_vpc && (
      var.vpc_create != null || var.project_create != null
    )
  )
  fleet_host = join("", [
    "https://connectgateway.googleapis.com/v1/",
    "projects/${local.fleet_project.number}/",
    "locations/global/gkeMemberships/${var.cluster_name}"
  ])
  fleet_project = (
    var.fleet_project_id == null
    ? {
      project_id = var.project_id
      number     = module.project.number
    }
    : {
      project_id = var.fleet_project_id
      number     = module.fleet-project[0].number
    }
  )
  proxy_only_subnet = (local.vpc_create && try(var.vpc_create.proxy_only_subnet, null) != null) ? [
    {
      ip_cidr_range = var.vpc_create.proxy_only_subnet
      name          = "proxy"
      region        = var.region
      active        = true
    }
  ] : null
  use_shared_vpc = (
    try(var.project_create.shared_vpc_host, null) != null
  )
}

module "project" {
  source          = "../../../../modules/project"
  parent          = try(var.project_create.parent, null)
  billing_account = try(var.project_create.billing_account, null)
  name            = var.project_id
  project_create  = var.project_create != null
  services = compact([
    "anthos.googleapis.com",
    var.registry_create ? "artifactregistry.googleapis.com" : null,
    "cloudresourcemanager.googleapis.com",
    "connectgateway.googleapis.com",
    "container.googleapis.com",
    "gkeconnect.googleapis.com",
    "gkehub.googleapis.com",
    "stackdriver.googleapis.com"
  ])
  shared_vpc_service_config = !local.use_shared_vpc ? null : {
    attach       = true
    host_project = var.project_create.shared_vpc_host
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
          : "serviceAccount:${module.fleet-project[0].service_accounts.robots.gkehub}"
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
  count      = local.vpc_create ? 1 : 0
  project_id = module.project.project_id
  name = coalesce(
    try(var.vpc_create.name, null), var.prefix
  )
  subnets = [{
    name = coalesce(
      try(var.vpc_create.subnet_name, null), "${var.prefix}-default"
    )
    region = var.region
    ip_cidr_range = try(
      var.vpc_create.primary_range_nodes, "10.0.0.0/24"
    )
    secondary_ip_ranges = {
      pods = try(
        var.vpc_create.secondary_range_pods, "10.16.0.0/20"
      )
      services = try(
        var.vpc_create.secondary_range_services, "10.32.0.0/24"
      )
    }
  }]
  subnets_proxy_only = local.proxy_only_subnet
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
      var.cluster_create != null
      ? module.cluster[0].id
      : "projects/${var.project_id}/locations/${var.region}/clusters/${var.cluster_name}"
    )
  }
}

module "registry" {
  source     = "../../../../modules/artifact-registry"
  count      = var.registry_create ? 1 : 0
  project_id = module.project.project_id
  location   = var.region
  name       = var.prefix
  format     = { docker = {} }
  mode       = { remote = true }
}

module "nat" {
  source         = "../../../../modules/net-cloudnat"
  count          = local.create_nat ? 1 : 0
  project_id     = module.project.project_id
  region         = var.region
  name           = "default"
  router_network = local.cluster_vpc.network
}
