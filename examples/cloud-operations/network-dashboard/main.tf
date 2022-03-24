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
  project_id_list = toset(var.monitored_projects_list)
  projects        = join(",", local.project_id_list)

  limit_instances          = join(",", local.limit_instances_list)
  limit_instances_list     = tolist(var.limit_instances)
  limit_instances_ppg      = join(",", local.limit_instances_ppg_list)
  limit_instances_ppg_list = tolist(var.limit_instances_ppg)
  limit_l4                 = join(",", local.limit_l4_list)
  limit_l4_list            = tolist(var.limit_l4)
  limit_l4_ppg             = join(",", local.limit_l4_ppg_list)
  limit_l4_ppg_list        = tolist(var.limit_l4_ppg)
  limit_l7                 = join(",", local.limit_l7_list)
  limit_l7_list            = tolist(var.limit_l7)
  limit_l7_ppg             = join(",", local.limit_l7_ppg_list)
  limit_l7_ppg_list        = tolist(var.limit_l7_ppg)
  limit_subnets            = join(",", local.limit_subnets_list)
  limit_subnets_list       = tolist(var.limit_subnets)
  limit_vpc_peer           = join(",", local.limit_vpc_peer_list)
  limit_vpc_peer_list      = tolist(var.limit_vpc_peer)
}

################################################
# Monitoring project creation                  #
################################################

module "project-monitoring" {
  source          = "../../../modules/project"
  name            = "monitoring"
  parent          = "organizations/${var.organization_id}"
  prefix          = var.prefix
  billing_account = var.billing_account
  services        = var.project_monitoring_services
}

################################################
# Service account creation and IAM permissions #
################################################

module "service-account-function" {
  source       = "../../../modules/iam-service-account"
  project_id   = module.project-monitoring.project_id
  name         = "sa-dash"
  generate_key = false

  # Required IAM permissions for this service account are:
  # 1) compute.networkViewer on projects to be monitored (I gave it at organization level for now for simplicity)
  # 2) monitoring viewer on the projects to be monitored (I gave it at organization level for now for simplicity)
  iam_organization_roles = {
    "${var.organization_id}" = [
      "roles/compute.networkViewer",
      "roles/monitoring.viewer",
      "roles/cloudasset.viewer"
    ]
  }

  iam_project_roles = {
    "${module.project-monitoring.project_id}" = [
      "roles/monitoring.metricWriter"
    ]
  }
}

################################################
# Cloud Function configuration (& Scheduler)   #
################################################

module "pubsub" {
  source     = "../../../modules/pubsub"
  project_id = module.project-monitoring.project_id
  name       = "network-dashboard-pubsub"
  subscriptions = {
    "network-dashboard-pubsub-default" = null
  }
  # the Cloud Scheduler robot service account already has pubsub.topics.publish
  # at the project level via roles/cloudscheduler.serviceAgent
}

resource "google_cloud_scheduler_job" "job" {
  project   = module.project-monitoring.project_id
  region    = var.region
  name      = "network-dashboard-scheduler"
  schedule  = var.schedule_cron
  time_zone = "UTC"

  pubsub_target {
    topic_name = module.pubsub.topic.id
    data       = base64encode("test")
  }
}

module "cloud-function" {
  source      = "../../../modules/cloud-function"
  project_id  = module.project-monitoring.project_id
  name        = "network-dashboard-cloud-function"
  bucket_name = "network-dashboard-bucket"
  bucket_config = {
    location             = var.region
    lifecycle_delete_age = null
  }

  bundle_config = {
    source_dir  = "cloud-function"
    output_path = "cloud-function.zip"
    excludes    = null
  }

  function_config = {
    timeout     = 180
    entry_point = "main"
    runtime     = "python39"
    instances   = 1
    memory      = 256
  }

  environment_variables = {
    LIMIT_INSTANCES         = local.limit_instances
    LIMIT_INSTANCES_PPG     = local.limit_instances_ppg
    LIMIT_L4                = local.limit_l4
    LIMIT_L4_PPG            = local.limit_l4_ppg
    LIMIT_L7                = local.limit_l7
    LIMIT_L7_PPG            = local.limit_l7_ppg
    LIMIT_SUBNETS           = local.limit_subnets
    LIMIT_VPC_PEER          = local.limit_vpc_peer
    MONITORED_PROJECTS_LIST = local.projects
    MONITORING_PROJECT_ID   = module.project-monitoring.project_id
    ORGANIZATION_ID         = var.organization_id
  }

  service_account = module.service-account-function.email

  trigger_config = {
    event    = "google.pubsub.topic.publish"
    resource = module.pubsub.topic.id
    retry    = null
  }
}

################################################
# Cloud Monitoring Dashboard creation          #
################################################

resource "google_monitoring_dashboard" "dashboard" {
  dashboard_json = file("${path.module}/dashboards/quotas-utilization.json")
  project        = module.project-monitoring.project_id
}
