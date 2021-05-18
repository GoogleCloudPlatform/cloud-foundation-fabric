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
#                                 Project                                     #
###############################################################################
module "project-id-datamart" {
  source         = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/project?ref=v4.2.0"
  name           = var.datamart_project_id
  project_create = false
}

###############################################################################
#                                   IAM                                       #
###############################################################################
module "datamart-default-service-accounts" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/iam-service-account?ref=v4.2.0"
  project_id = var.datamart_project_id

  name = var.datamart_service_account

  iam_project_roles = {
    "${var.datamart_project_id}" = [
      "roles/editor",
    ]
  }
}

###############################################################################
#                                 Bigquery                                    #
###############################################################################
data "google_service_account" "datamart" {
  account_id = var.datamart_service_account
  project    = var.datamart_project_id
}

module "bigquery-datasets-datamart" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/bigquery-dataset?ref=v4.2.0"
  project_id = var.datamart_project_id

  for_each = var.datamart_bq_datasets

  id       = each.value.id
  location = each.value.location

  access = {
    owner = { role = "OWNER", type = "user" }
  }
  access_identities = {
    owner = module.datamart-default-service-accounts.email
  }
}
