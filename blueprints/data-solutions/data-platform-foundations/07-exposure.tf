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

# tfdoc:file:description common project.

locals {
  exp_group_iam = {
    (local.groups.data-engineers) = [
      "roles/bigquery.admin",
      "roles/storage.admin",
      "roles/analyticshub.admin",
      "roles/analyticshub.publisher",
      "roles/analyticshub.listingAdmin"
    ],
    (local.groups.data-analysts) = [
      "roles/analyticshub.viewer",
      "roles/bigquery.dataViewer",
      "roles/bigquery.jobUser",
      "roles/bigquery.metadataViewer",
      "roles/bigquery.user",
      "roles/datacatalog.viewer",
      "roles/datacatalog.tagTemplateViewer",
      "roles/storage.objectViewer",
    ]
  }
  exp_iam = {
    "roles/bigquery.dataOwner" = [
      module.transf-sa-df-0.iam_email,
      module.transf-sa-bq-0.iam_email,
    ]
    "roles/bigquery.jobUser" = [
      module.transf-sa-bq-0.iam_email,
    ]
    "roles/datacatalog.categoryAdmin" = [
      module.load-sa-df-0.iam_email
    ]
    "roles/storage.objectCreator" = [
      module.transf-sa-df-0.iam_email,
    ]
    "roles/storage.objectViewer" = [
      module.transf-sa-df-0.iam_email,
    ]
  }
  exp_services = concat(var.project_services, [
    "bigquery.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudkms.googleapis.com",
    "pubsub.googleapis.com",
    "storage.googleapis.com",
    "storage-component.googleapis.com"
  ])
}

module "exp-project" {
  source          = "../../../modules/project"
  parent          = var.folder_id
  billing_account = var.billing_account_id
  prefix          = var.prefix
  name            = "exp${local.project_suffix}"
  group_iam       = local.exp_group_iam
  iam             = local.exp_iam
  services        = local.exp_services
}
