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

# tfdoc:file:description Landing project and resources.

locals {
  iam_ga_lnd = {
    "roles/storage.objectCreator" = [module.ga-land-sa-0.iam_email]
    "roles/storage.objectViewer"  = [module.processing-sa-cmp-0.iam_email]
    "roles/storage.objectAdmin"   = [module.processing-sa-0.iam_email]
  }
}

module "ga-land-project" {
  source          = "../../../modules/project"
  parent          = var.project_config.parent
  billing_account = var.project_config.billing_account_id
  project_create  = var.project_config.billing_account_id != null
  prefix          = var.project_config.billing_account_id == null ? null : var.prefix
  name = (
    var.project_config.billing_account_id == null
    ? var.project_config.project_ids.ga_landing
    : "${var.project_config.project_ids.ga_landing}${local.project_suffix}"
  )
  iam          = var.project_config.billing_account_id != null ? local.iam_ga_lnd : null
  iam_additive = var.project_config.billing_account_id == null ? local.iam_ga_lnd : null
  services = [
    "bigquery.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "serviceusage.googleapis.com",
    "stackdriver.googleapis.com",
    "storage.googleapis.com",
    "storage-component.googleapis.com",
  ]
  service_encryption_key_ids = {
    bq      = [var.service_encryption_keys.bq]
    storage = [var.service_encryption_keys.storage]
  }
  tag_bindings = {
    drs-allow-all = var.tag_values["org-policies/allowed-policy-member-domains-all"]
  }
}

# Cloud Storage

module "ga-land-sa-0" {
  source       = "../../../modules/iam-service-account"
  project_id   = module.ga-land-project.project_id
  prefix       = var.prefix
  name         = "ga-lnd-sa-0"
  display_name = "Data platform GA landing zone service account."
  iam = {
    "roles/iam.serviceAccountTokenCreator" = [
      local.groups_iam.data-engineers
    ]
  }
}

module "ga-land-bq-0" {
  count   = var.enable_services.composer != null ? 1 : 0
  source         = "../../../modules/bigquery-dataset"
  project_id     = module.ga-land-project.project_id
  id             = var.google_analytics_property_id
  location       = var.location
  encryption_key = var.service_encryption_keys.bq
  depends_on = [
    module.ga-land-project
  ]
}
