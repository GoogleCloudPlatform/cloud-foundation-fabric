/**
 * Copyright 2025 Google LLC
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

# tfdoc:file:description Billing export project and dataset.

locals {
  # used here for convenience, in organization.tf members are explicit
  billing_ext_admins = [
    local.principals.gcp-billing-admins,
    local.principals.gcp-organization-admins,
    module.automation-tf-bootstrap-sa.iam_email,
    module.automation-tf-resman-sa.iam_email
  ]
  billing_ext_viewers = [
    module.automation-tf-bootstrap-r-sa.iam_email,
    module.automation-tf-resman-r-sa.iam_email
  ]
  billing_ext_log_writers = [
    module.automation-tf-bootstrap-sa.iam_email
  ]
  billing_mode = (
    var.billing_account.no_iam
    ? null
    : var.billing_account.is_org_level ? "org" : "resource"
  )
}

# billing account in same org (IAM is in the organization.tf file)

module "billing-export-project" {
  source = "../../../modules/project"
  count = (
    local.billing_mode == "org" || var.billing_account.force_create.project == true ? 1 : 0
  )
  billing_account = var.billing_account.id
  name            = var.resource_names["project-billing"]
  parent = coalesce(
    var.project_parent_ids.billing, "organizations/${var.organization.id}"
  )
  prefix   = var.prefix
  universe = var.universe
  contacts = (
    var.bootstrap_user != null || var.essential_contacts == null
    ? {}
    : { (var.essential_contacts) = ["ALL"] }
  )
  iam = {
    "roles/owner"  = [module.automation-tf-bootstrap-sa.iam_email]
    "roles/viewer" = [module.automation-tf-bootstrap-r-sa.iam_email]
  }
  services = [
    # "cloudresourcemanager.googleapis.com",
    # "iam.googleapis.com",
    # "serviceusage.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "storage.googleapis.com"
  ]
}

module "billing-export-dataset" {
  source = "../../../modules/bigquery-dataset"
  count = (
    local.billing_mode == "org" || var.billing_account.force_create.dataset == true ? 1 : 0
  )
  project_id    = module.billing-export-project[0].project_id
  id            = var.resource_names["bq-billing"]
  friendly_name = "Billing export."
  location      = local.locations.bq
}

# standalone billing account

resource "google_billing_account_iam_member" "billing_ext_admin" {
  for_each = toset(
    local.billing_mode == "resource" ? local.billing_ext_admins : []
  )
  billing_account_id = var.billing_account.id
  role               = "roles/billing.admin"
  member             = each.key
}

resource "google_billing_account_iam_member" "billing_ext_viewer" {
  for_each = toset(
    local.billing_mode == "resource" ? local.billing_ext_viewers : []
  )
  billing_account_id = var.billing_account.id
  role               = "roles/billing.viewer"
  member             = each.key
}

resource "google_billing_account_iam_member" "billing_ext_log_writer" {
  for_each = toset(
    local.billing_mode == "resource" ? local.billing_ext_log_writers : []
  )
  billing_account_id = var.billing_account.id
  role               = "roles/logging.configWriter"
  member             = each.key
}

module "billing-account-logbucket" {
  source        = "../../../modules/logging-bucket"
  count         = local.billing_mode == "resource" ? 1 : 0
  parent_type   = "project"
  parent        = module.log-export-project.project_id
  id            = "billing-account"
  location      = local.locations.logging
  log_analytics = { enable = true }
  # org-level logging settings ready before we create any logging buckets
  depends_on = [module.organization-logging]
}

module "billing-account-log-sink" {
  source = "../modules/billing-account"
  count  = local.billing_mode == "resource" ? 1 : 0
  id     = var.billing_account.id
  logging_sinks = {
    billing_bucket_log_sink = {
      destination = module.billing-account-logbucket[0].id
      type        = "logging"
      description = "billing-account sink (Terraform-managed)."
    }
  }
}