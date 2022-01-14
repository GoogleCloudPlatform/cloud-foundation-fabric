# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module "service-account-bq" {
  source     = "../../../modules/iam-service-account"
  project_id = module.project.project_id
  name       = "bq-test"
  prefix     = var.prefix
  iam_project_roles = {
    (module.project.project_id) = [
      "roles/bigquery.admin",
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
    ]
  }
}

module "service-account-df" {
  source     = "../../../modules/iam-service-account"
  project_id = module.project.project_id
  name       = "df-test"
  prefix     = var.prefix
  iam_project_roles = {
    (module.project.project_id) = [
      "roles/bigquery.dataOwner",
      "roles/bigquery.jobUser",
      "roles/bigquery.metadataViewer",
      "roles/dataflow.worker",
      "roles/storage.objectViewer",
    ]
  }
}

module "service-account-gce" {
  source     = "../../../modules/iam-service-account"
  project_id = module.project.project_id
  name       = "gce-test"
  prefix     = var.prefix
  iam_project_roles = {
    (module.project.project_id) = [
      "roles/bigquery.dataOwner",
      "roles/bigquery.jobUser",
      "roles/dataflow.admin",
      "roles/iam.serviceAccountUser",
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
    ]
  }
}
