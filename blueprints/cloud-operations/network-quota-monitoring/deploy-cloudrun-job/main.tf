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

# TODO: support custom quota file

locals {
  discovery_roles = ["roles/compute.viewer", "roles/cloudasset.viewer"]
}

module "project" {
  source          = "../../../../modules/project"
  name            = var.project_id
  billing_account = try(var.project_create_config.billing_account_id, null)
  parent          = try(var.project_create_config.parent_id, null)
  project_create  = var.project_create_config != null
  services = [
    "artifactregistry.googleapis.com",
    "cloudasset.googleapis.com",
    "cloudscheduler.googleapis.com",
    "compute.googleapis.com",
    "monitoring.googleapis.com",
    "run.googleapis.com"
  ]
}

module "ar" {
  source     = "../../../../modules/artifact-registry"
  project_id = module.project.project_id
  location   = var.region
  name       = var.name
  format     = { docker = { standard = {} } }
}

module "sa" {
  source       = "../../../../modules/iam-service-account"
  project_id   = module.project.project_id
  name         = var.name
  display_name = "Net monitoring service."
  iam_project_roles = {
    (module.project.project_id) = [
      "roles/monitoring.metricWriter"
    ]
  }
}

module "sa-invoker" {
  source       = "../../../../modules/iam-service-account"
  project_id   = module.project.project_id
  name         = "${var.name}-invoker"
  display_name = "Net monitoring service invoker."
}

module "cr-job" {
  source     = "../../../../modules/cloud-run-v2"
  project_id = module.project.project_id
  name       = var.name
  region     = var.region
  create_job = true
  containers = {
    netmon = {
      image = "${module.ar.url}/${var.name}"
      args = concat(
        [
          "-dr",
          var.discovery_config.discovery_root,
          "-mon",
          coalesce(var.monitoring_project, module.project.project_id)
        ],
        flatten([
          for f in var.discovery_config.monitored_folders : [
            "-f", f
          ]
        ]),
        flatten([
          for f in var.discovery_config.monitored_projects : [
            "-p", f
          ]
        ])
      )
    }
  }
  iam = {
    "roles/run.invoker" = [
      module.sa-invoker.iam_email
    ]
  }
  revision = {
    job = {
      max_retries = 0
    }
  }
  service_account     = module.sa.email
  deletion_protection = false
}

resource "google_cloud_scheduler_job" "job" {
  name             = var.name
  description      = "Schedule net monitor job."
  schedule         = var.schedule_config.crontab
  time_zone        = "UTC"
  attempt_deadline = "320s"
  region           = coalesce(var.schedule_config.region, var.region)
  project          = module.project.project_id
  retry_config {
    retry_count = 1
  }
  http_target {
    http_method = "POST"
    uri         = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${module.project.number}/jobs/${var.name}:run"
    oauth_token {
      service_account_email = module.sa-invoker.email
    }
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
  member = module.sa.iam_email
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
  member = module.sa.iam_email
}

resource "google_monitoring_dashboard" "dashboard" {
  count          = var.dashboard_json_path == null ? 0 : 1
  project        = var.project_id
  dashboard_json = file(var.dashboard_json_path)
}
