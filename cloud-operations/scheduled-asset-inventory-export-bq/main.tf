/**
 * Copyright 2020 Google LLC
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

###############################################################################
#                                Projects                                     #
###############################################################################
module "project" {
  source          = "../../modules/project"
  name            = var.project_id
  parent          = "folders/572946148602"
  billing_account = "0074F6-6FDF57-1B2DD0"
  project_create  = var.project_create
  services = [
    "bigquery.googleapis.com",
    "cloudasset.googleapis.com",
    "compute.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudscheduler.googleapis.com",
    "pubsub.googleapis.com"
  ]
}

module "service-account" {
  source     = "../../modules/iam-service-accounts"
  project_id = module.project.project_id
  names      = ["${var.name}-cf"]
  iam_project_roles = {
    (module.project.name) = [
      "roles/cloudasset.viewer",
      "roles/cloudfunctions.invoker"
    ]
  }
}

###############################################################################
#                                Pub/Sub                                      #
###############################################################################
module "pubsub" {
  source     = "../../modules/pubsub"
  project_id = module.project.project_id
  name       = var.name
  subscriptions = {
    "${var.name}-default" = null
  }
  # the Cloud Scheduler robot service account already has pubsub.topics.publish
  # at the project level via roles/cloudscheduler.serviceAgent
}

###############################################################################
#                             Cloud Function                                  #
###############################################################################
module "cf" {
  source      = "../../modules/cloud-function"
  project_id  = module.project.project_id
  name        = var.name
  bucket_name = "${var.name}-${random_pet.random.id}"
  bucket_config = {
    location             = var.region
    lifecycle_delete_age = null
  }
  bundle_config = {
    source_dir  = "cf"
    output_path = var.bundle_path
  }
  service_account = module.service-account.email
  iam_roles       = ["roles/cloudfunctions.invoker"]
  iam_members = {
    "roles/cloudfunctions.invoker" = ["serviceAccount:${module.service-account.email}"]
  }
  trigger_config = {
    event    = "google.pubsub.topic.publish"
    resource = module.pubsub.topic.id
    retry    = null
  }
}

resource "random_pet" "random" {
  length = 1
}

###############################################################################
#                            Cloud Scheduler                                  #
###############################################################################
resource "google_app_engine_application" "app" {
  project     = module.project.project_id
  location_id = "europe-west"
}

resource "google_cloud_scheduler_job" "job" {
  project          = module.project.project_id
  region           = var.region
  name             = "test-job"
  description      = "test http job"
  schedule         = "* 9 * * 1"
  time_zone        = "Etc/UTC"
  attempt_deadline = "320s"

  pubsub_target {
    attributes = {}
    topic_name = module.pubsub.topic.id
    data = base64encode(jsonencode({
      organization = var.cai_config.organization
      bq_project   = var.project_id
      bq_dataset   = var.cai_config.bq_dataset
      bq_table     = var.cai_config.bq_table
    }))
  }
}

###############################################################################
#                                Bigquery                                     #
###############################################################################
module "bigquery-dataset" {
  source     = "../../modules/bigquery-dataset"
  project_id = module.project.project_id
  id         = var.cai_config.bq_dataset
  access_roles = {
    owner = { role = "OWNER", type = "user_by_email" }
  }
  access_identities = {
    owner = module.service-account.email
  }
}
