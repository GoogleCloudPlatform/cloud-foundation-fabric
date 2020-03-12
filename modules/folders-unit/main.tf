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

locals {

  iam_bindings = {
    for role in var.iam_roles :
    role => lookup(var.iam_members, role, [])
  }
  iam_service_account_bindings = {
    for pair in setproduct(var.environments, var.iam_enviroment_roles) :
    "${pair.0}-${pair.1}" => { environment = pair.0, role = pair.1 }
  }
  service_accounts = {
    for key, sa in google_service_account.environment :
    key => "serviceAccount:${sa.email}"
  }
}

################################################################################
#                            Folders and folder IAM                            #
################################################################################

resource "google_folder" "unit" {
  display_name = var.name
  parent       = var.parent
}

resource "google_folder" "environment" {
  for_each     = toset(var.environments)
  display_name = each.value
  parent       = google_folder.unit.name
}

resource "google_folder_iam_binding" "authoritative" {
  for_each = local.iam_bindings
  folder   = google_folder.unit.name
  role     = each.key
  members  = each.value
}

resource "google_folder_iam_binding" "environment" {
  for_each = local.iam_service_account_bindings
  folder   = google_folder.environment[each.value.environment].name
  role     = each.value.role
  members = [
    "serviceAccount:${google_service_account.environment[each.value.environment.email]}"
  ]
}

################################################################################
#                         Service Accounts and SA IAM                          #
################################################################################

resource "google_service_account" "environment" {
  for_each     = toset(var.environments)
  project      = var.automation_project_id
  account_id   = "${var.name}-${each.value}"
  display_name = "${var.name} ${each.value} (Terraform managed)."
}

resource "google_billing_account_iam_member" "billing-user" {
  for_each           = local.service_accounts
  billing_account_id = var.billing_account_id
  role               = "roles/billing.user"
  member             = each.value
}

# TODO: remember to add org-level roles if the service accounts need to manage
#       Shared VPC inside the Prod/Non-prod folders

################################################################################
#                               GCS and GCS IAM                                #
################################################################################

resource "google_storage_bucket" "bucket" {
  for_each           = toset(var.environments)
  project            = var.automation_project_id
  name               = "${var.prefix}-${var.name}-${each.value}-tf"
  location           = var.gcs_defaults.location
  storage_class      = var.gcs_defaults.storage_class
  force_destroy      = false
  bucket_policy_only = true
  versioning {
    enabled = true
  }
}

resource "google_storage_bucket_iam_binding" "bindings" {
  for_each = toset(var.environments)
  bucket   = google_storage_bucket.bucket[each.value].name
  role     = "roles/storage.objectAdmin"
  members  = [local.service_accounts[each.value]]
}
