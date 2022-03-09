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

  limit_subnets_list       = tolist(var.limit_subnets)
  limit_subnets            = join(",", local.limit_subnets_list)
  limit_instances_list     = tolist(var.limit_instances)
  limit_instances          = join(",", local.limit_instances_list)
  limit_instances_ppg_list = tolist(var.limit_instances_ppg)
  limit_instances_ppg      = join(",", local.limit_instances_ppg_list)
  limit_vpc_peer_list      = tolist(var.limit_vpc_peer)
  limit_vpc_peer           = join(",", local.limit_vpc_peer_list)
  limit_l4_list            = tolist(var.limit_l4)
  limit_l4                 = join(",", local.limit_l4_list)
  limit_l7_list            = tolist(var.limit_l7)
  limit_l7                 = join(",", local.limit_l7_list)
  limit_l4_ppg_list        = tolist(var.limit_l4_ppg)
  limit_l4_ppg             = join(",", local.limit_l4_ppg_list)
  limit_l7_ppg_list        = tolist(var.limit_l7_ppg)
  limit_l7_ppg             = join(",", local.limit_l7_ppg_list)
}

################################################
# Monitoring project creation                  #
################################################

module "project-monitoring" {
  source          = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v14.0.0"
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
  source       = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v14.0.0"
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

# Create an app engine application (required for Cloud Scheduler)
resource "google_app_engine_application" "scheduler_app" {
  project = module.project-monitoring.project_id
  # "europe-west1" is called "europe-west" and "us-central1" is "us-central" for App Engine, see https://cloud.google.com/appengine/docs/locations
  location_id = var.region == "europe-west1" || var.region == "us-central1" ? substr(var.region, 0, length(var.region) - 1) : var.region
}

# Create a storage bucket for the Cloud Function's code
resource "google_storage_bucket" "bucket" {
  name     = "net-quotas-bucket"
  location = "EU"
  project  = module.project-monitoring.project_id

}

data "archive_file" "file" {
  type        = "zip"
  source_dir  = "cloud-function"
  output_path = "cloud-function.zip"
  depends_on  = [google_storage_bucket.bucket]
}

resource "google_storage_bucket_object" "archive" {
  # md5 hash in the bucket object name to redeploy the Cloud Function when the code is modified
  name       = format("cloud-function#%s", data.archive_file.file.output_md5)
  bucket     = google_storage_bucket.bucket.name
  source     = "cloud-function.zip"
  depends_on = [data.archive_file.file]
}

resource "google_cloudfunctions_function" "function_quotas" {
  name        = "function-quotas"
  project     = module.project-monitoring.project_id
  region      = var.region
  description = "Function which creates metric to show number, limit and utlizitation."
  runtime     = "python39"

  available_memory_mb   = 512
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.archive.name
  service_account_email = module.service-account-function.email

  timeout      = 180
  entry_point  = "quotas"
  trigger_http = true


  environment_variables = {
    monitored_projects_list = local.projects
    monitoring_project_id   = module.project-monitoring.project_id

    LIMIT_SUBNETS       = local.limit_subnets
    LIMIT_INSTANCES     = local.limit_instances
    LIMIT_INSTANCES_PPG = local.limit_instances_ppg
    LIMIT_VPC_PEER      = local.limit_vpc_peer
    LIMIT_L4            = local.limit_l4
    LIMIT_L7            = local.limit_l7
    LIMIT_L4_PPG        = local.limit_l4_ppg
    LIMIT_L7_PPG        = local.limit_l7_ppg
  }
}

resource "google_cloud_scheduler_job" "job" {
  name        = "scheduler-net-dash"
  project     = module.project-monitoring.project_id
  region      = var.region
  description = "Cloud Scheduler job to trigger the Networking Dashboard Cloud Function"
  schedule    = var.schedule_cron

  retry_config {
    retry_count = 1
  }

  http_target {
    http_method = "POST"
    uri         = google_cloudfunctions_function.function_quotas.https_trigger_url
    # We could pass useful data in the body later
    body = base64encode("{\"foo\":\"bar\"}")
  }
}

# TODO: How to secure Cloud Function invokation? Not   member = "allUsers" but specific Scheduler service Account?
# Maybe "service-YOUR_PROJECT_NUMBER@gcp-sa-cloudscheduler.iam.gserviceaccount.com"?

resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = module.project-monitoring.project_id
  region         = var.region
  cloud_function = google_cloudfunctions_function.function_quotas.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

################################################
# Cloud Monitoring Dashboard creation          #
################################################

resource "google_monitoring_dashboard" "dashboard" {
  dashboard_json = file("${path.module}/dashboards/quotas-utilization.json")
  project        = module.project-monitoring.project_id
}
