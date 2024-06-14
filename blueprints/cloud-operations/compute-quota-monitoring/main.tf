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
  projects = (
    var.quota_config.projects == null
    ? [var.project_id]
    : var.quota_config.projects
  )
  discovery_root_type = split("/", coalesce(var.quota_config["discovery_root"], "/"))[0]
  discovery_root_id   = split("/", coalesce(var.quota_config["discovery_root"], "/"))[1]
}

module "project" {
  source          = "../../../modules/project"
  name            = var.project_id
  billing_account = try(var.project_create_config.billing_account, null)
  parent          = try(var.project_create_config.parent, null)
  project_create  = var.project_create_config != null
  services = [
    "cloudasset.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudscheduler.googleapis.com",
    "compute.googleapis.com"
  ]
}

module "pubsub" {
  source     = "../../../modules/pubsub"
  project_id = module.project.project_id
  name       = var.name
  subscriptions = {
    "${var.name}-default" = {}
  }
  # the Cloud Scheduler robot service account already has pubsub.topics.publish
  # at the project level via roles/cloudscheduler.serviceAgent
}

module "cf" {
  source      = "../../../modules/cloud-function-v1"
  project_id  = module.project.project_id
  region      = var.region
  name        = var.name
  bucket_name = "${var.name}-${random_pet.random.id}"
  bucket_config = {
    location = var.region
  }
  bundle_config = {
    path = "${path.module}/src"
    folder_options = {
      archive_path = var.bundle_path
    }
  }
  service_account_create = true
  trigger_config = {
    event    = "google.pubsub.topic.publish"
    resource = module.pubsub.topic.id
  }
}

resource "google_cloud_scheduler_job" "default" {
  project   = module.project.project_id
  region    = var.region
  name      = var.name
  schedule  = var.schedule_config
  time_zone = "UTC"
  pubsub_target {
    attributes = {}
    topic_name = module.pubsub.topic.id
    data = base64encode(jsonencode(merge(
      { monitoring_project = var.project_id },
      var.quota_config
    )))
  }
}

resource "google_organization_iam_member" "org_asset_viewer" {
  count  = local.discovery_root_type == "organizations" ? 1 : 0
  org_id = local.discovery_root_id
  role   = "roles/cloudasset.viewer"
  member = module.cf.service_account_iam_email
}


# role with the least privilege including compute.projects.get permission
resource "google_organization_iam_member" "org_network_viewer" {
  count  = local.discovery_root_type == "organizations" ? 1 : 0
  org_id = local.discovery_root_id
  role   = "roles/compute.networkViewer"
  member = module.cf.service_account_iam_email
}

resource "google_organization_iam_member" "org_quota_viewer" {
  count  = local.discovery_root_type == "organizations" ? 1 : 0
  org_id = local.discovery_root_id
  role   = "roles/servicemanagement.quotaViewer"
  member = module.cf.service_account_iam_email
}

resource "google_folder_iam_member" "folder_asset_viewer" {
  count  = local.discovery_root_type == "folders" ? 1 : 0
  folder = local.discovery_root_id
  role   = "roles/cloudasset.viewer"
  member = module.cf.service_account_iam_email
}

# role with the least privilege including compute.projects.get permission
resource "google_folder_iam_member" "folder_network_viewer" {
  count  = local.discovery_root_type == "folders" ? 1 : 0
  folder = local.discovery_root_id
  role   = "roles/compute.networkViewer"
  member = module.cf.service_account_iam_email
}

resource "google_folder_iam_member" "folder_quota_viewer" {
  count  = local.discovery_root_type == "folders" ? 1 : 0
  folder = local.discovery_root_id
  role   = "roles/servicemanagement.quotaViewer"
  member = module.cf.service_account_iam_email
}





resource "google_project_iam_member" "metric_writer" {
  project = module.project.project_id
  role    = "roles/monitoring.metricWriter"
  member  = module.cf.service_account_iam_email
}

resource "google_project_iam_member" "network_viewer" {
  for_each = toset(local.projects)
  project  = each.key
  role     = "roles/compute.networkViewer"
  member   = module.cf.service_account_iam_email
}

resource "google_project_iam_member" "quota_viewer" {
  for_each = toset(local.projects)
  project  = each.key
  role     = "roles/servicemanagement.quotaViewer"
  member   = module.cf.service_account_iam_email
}

resource "google_monitoring_alert_policy" "default" {
  for_each     = var.alert_configs
  project      = module.project.project_id
  display_name = "Monitor quota ${each.key}"
  combiner     = "OR"
  conditions {
    display_name = "Threshold ${each.value.threshold} for ${each.key}."
    condition_threshold {
      filter          = "metric.type=\"custom.googleapis.com/quota/${each.key}\" resource.type=\"global\""
      threshold_value = each.value.threshold
      comparison      = "COMPARISON_GT"
      duration        = "0s"
      aggregations {
        alignment_period   = "60s"
        group_by_fields    = []
        per_series_aligner = "ALIGN_MEAN"
      }
      trigger {
        count   = 1
        percent = 0
      }
    }
  }
  enabled     = each.value.enabled
  user_labels = each.value.labels
  documentation {
    content = (
      each.value.documentation != null
      ? each.value.documentation
      : "Quota over threshold of ${each.value.threshold} for ${each.key}."
    )
  }
}

resource "random_pet" "random" {
  length = 1
}
