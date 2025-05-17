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
  fleet_host = join("", [
    "https://connectgateway.googleapis.com/v1/",
    "projects/${module.project.number}/",
    "locations/global/gkeMemberships/${var.chronicle_forwarder.cluster_name}"
  ])
}

module "project" {
  source = "../../../modules/project"
  billing_account = (var.project_create != null
    ? var.project_create.billing_account_id
    : null
  )
  parent = (var.project_create != null
    ? var.project_create.parent
    : null
  )
  prefix        = var.prefix
  project_reuse = var.project_create != null ? null : {}
  name          = var.project_id
  services = concat([
    "compute.googleapis.com",
    "chronicle.googleapis.com",
    "connectgateway.googleapis.com",
    "container.googleapis.com",
    "gkeconnect.googleapis.com",
    "gkehub.googleapis.com",
    "iap.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ])
}

module "fleet" {
  source     = "../../../modules/gke-hub"
  project_id = var.project_id
  clusters = {
    "chronicle-log-ingestion" = module.chronicle-forwarder.id
  }
}

module "chronicle-forwarder" {
  source              = "../../../modules/gke-cluster-autopilot"
  project_id          = var.project_id
  name                = var.chronicle_forwarder.cluster_name
  location            = var.region
  deletion_protection = false
  access_config = {
    ip_access = {
      authorized_ranges = var.chronicle_forwarder.master_authorized_ranges
    }
  }
  vpc_config = {
    network    = var.network_config.network_self_link
    subnetwork = var.network_config.subnet_self_link
    secondary_range_names = {
      pods     = "pods"
      services = "services"
    }
  }
  enable_features = {
    gateway_api = true
  }
  logging_config = {
    enable_api_server_logs         = true
    enable_scheduler_logs          = true
    enable_controller_manager_logs = true
  }
  monitoring_config = {
    enable_daemonset_metrics          = true
    enable_deployment_metrics         = true
    enable_hpa_metrics                = true
    enable_pod_metrics                = true
    enable_statefulset_metrics        = true
    enable_storage_metrics            = true
    enable_api_server_metrics         = true
    enable_controller_manager_metrics = true
    enable_scheduler_metrics          = true
  }
}

module "chronicle-forwarder-deployment" {
  source     = "./secops-forwarder-deployment"
  depends_on = [module.chronicle-forwarder]
  tenants    = var.tenants
}
