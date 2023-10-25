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
  discovery_roles = ["roles/compute.viewer", "roles/cloudasset.viewer"]
}

resource "random_string" "default" {
  count   = var.cloud_function_config.bucket_name == null ? 1 : 0
  length  = 8
  special = false
  upper   = false
}

module "project" {
  source          = "../../../../modules/project"
  name            = var.project_id
  billing_account = try(var.project_create_config.billing_account_id, null)
  labels          = var.project_create_config != null ? var.labels : null
  parent          = try(var.project_create_config.parent_id, null)
  project_create  = var.project_create_config != null
  services = [
    "cloudasset.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudscheduler.googleapis.com",
    "compute.googleapis.com",
    "monitoring.googleapis.com"
  ]
}

module "pubsub" {
  source        = "../../../../modules/pubsub"
  project_id    = module.project.project_id
  name          = var.name
  regions       = [var.region]
  subscriptions = {}
}

module "cloud-function" {
  source     = "../../../../modules/cloud-function-v1"
  project_id = module.project.project_id
  name       = var.name
  bucket_name = coalesce(
    var.cloud_function_config.bucket_name,
    "${var.name}-${random_string.default.0.id}"
  )
  bucket_config = {
    location = var.region
  }
  build_worker_pool = var.cloud_function_config.build_worker_pool_id
  bundle_config = {
    source_dir  = var.cloud_function_config.source_dir
    output_path = var.cloud_function_config.bundle_path
  }
  environment_variables = (
    var.cloud_function_config.debug != true ? {} : { DEBUG = "1" }
  )
  function_config = {
    entry_point     = "main_cf_pubsub"
    memory_mb       = var.cloud_function_config.memory_mb
    timeout_seconds = var.cloud_function_config.timeout_seconds
  }
  service_account_create = true
  trigger_config = {
    event    = "google.pubsub.topic.publish"
    resource = module.pubsub.topic.id
  }
  vpc_connector = (
    var.cloud_function_config.vpc_connector == null
    ? null
    : {
      create          = false
      name            = var.cloud_function_config.vpc_connector.name
      egress_settings = var.cloud_function_config.vpc_connector.egress_settings
    }
  )
}

resource "google_cloud_scheduler_job" "default" {
  project   = var.project_id
  region    = var.region
  name      = var.name
  schedule  = var.schedule_config
  time_zone = "UTC"

  pubsub_target {
    attributes = {}
    topic_name = module.pubsub.topic.id
    data = base64encode(jsonencode({
      discovery_root = var.discovery_config.discovery_root
      folders        = var.discovery_config.monitored_folders
      projects       = var.discovery_config.monitored_projects
      monitoring_project = (
        var.monitoring_project == null
        ? module.project.project_id
        : var.monitoring_project
      )
      custom_quota = (
        var.discovery_config.custom_quota_file == null
        ? { networks = {}, projects = {} }
        : yamldecode(file(var.discovery_config.custom_quota_file))
      )
    }))
  }
}

resource "google_organization_iam_member" "discovery" {
  for_each = toset(
    var.grant_discovery_iam_roles &&
    startswith(var.discovery_config.discovery_root, "organizations/")
    ? local.discovery_roles
    : []
  )
  org_id = split("/", var.discovery_config.discovery_root)[1]
  role   = each.key
  member = module.cloud-function.service_account_iam_email
}

resource "google_folder_iam_member" "discovery" {
  for_each = toset(
    var.grant_discovery_iam_roles &&
    startswith(var.discovery_config.discovery_root, "folders/")
    ? local.discovery_roles
    : []
  )
  folder = var.discovery_config.discovery_root
  role   = each.key
  member = module.cloud-function.service_account_iam_email
}

resource "google_project_iam_member" "monitoring" {
  project = module.project.project_id
  role    = "roles/monitoring.metricWriter"
  member  = module.cloud-function.service_account_iam_email
}

resource "google_monitoring_dashboard" "dashboard" {
  count          = var.dashboard_json_path == null ? 0 : 1
  project        = var.project_id
  dashboard_json = file(var.dashboard_json_path)
}
