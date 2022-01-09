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
  organization_id = element(split("/", var.organization_id), 1)
}

###############################################################################
#                            Folders and folder IAM                           #
###############################################################################

resource "google_folder" "unit" {
  display_name = var.name
  parent       = var.root_node
}

resource "google_folder" "environment" {
  for_each     = var.environments
  display_name = each.value
  parent       = google_folder.unit.name
}

resource "google_folder_iam_binding" "unit" {
  for_each = var.iam
  folder   = google_folder.unit.name
  role     = each.key
  members  = each.value
}

resource "google_folder_iam_binding" "environment" {
  for_each = local.folder_iam_service_account_bindings
  folder   = google_folder.environment[each.value.environment].name
  role     = each.value.role
  members  = [local.service_accounts[each.value.environment]]
}

###############################################################################
#                         Billing account and org IAM                         #
###############################################################################

resource "google_organization_iam_member" "org_iam_member" {
  for_each = local.org_iam_service_account_bindings
  org_id   = local.organization_id
  role     = each.value.role
  member   = local.service_accounts[each.value.environment]
}

resource "google_billing_account_iam_member" "billing_iam_member" {
  for_each           = var.iam_billing_config.grant ? local.billing_iam_service_account_bindings : {}
  billing_account_id = var.billing_account_id
  role               = each.value.role
  member             = local.service_accounts[each.value.environment]
}

################################################################################
#                                Service Accounts                              #
################################################################################

resource "google_service_account" "environment" {
  for_each     = var.environments
  project      = var.automation_project_id
  account_id   = "${var.short_name}-${each.key}"
  display_name = "${var.short_name} ${each.key} (Terraform managed)."
}

resource "google_service_account_key" "keys" {
  for_each           = var.service_account_keys ? var.environments : {}
  service_account_id = google_service_account.environment[each.key].email
}

################################################################################
#                               GCS and GCS IAM                                #
################################################################################

resource "google_storage_bucket" "tfstate" {
  for_each = var.environments
  project  = var.automation_project_id
  name = join("", [
    var.prefix == null ? "" : "${var.prefix}-",
    "${var.short_name}-${each.key}-tf"
  ])
  location                    = var.gcs_defaults.location
  storage_class               = var.gcs_defaults.storage_class
  force_destroy               = false
  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }
}

resource "google_storage_bucket_iam_binding" "bindings" {
  for_each = var.environments
  bucket   = google_storage_bucket.tfstate[each.key].name
  role     = "roles/storage.objectAdmin"
  members  = [local.service_accounts[each.key]]
}
