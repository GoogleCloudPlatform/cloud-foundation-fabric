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


###############################################################################
#                                 GCP PROJECT                                 #
###############################################################################

module "project" {
  source          = "../../../../modules/project"
  name            = var.project_id
  project_create  = var.project_create
  parent          = var.parent
  billing_account = var.billing_account
  services = [
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
    "storage.googleapis.com"
  ]
}

###############################################################################
#                     Workload Identity Pool and Provider                     #
###############################################################################

resource "google_iam_workload_identity_pool" "tfe-pool" {
  project                   = module.project.project_id
  workload_identity_pool_id = var.workload_identity_pool_id
  display_name              = "TFE Pool"
  description               = "Identity pool for Terraform Enterprise OIDC integration"
}

resource "google_iam_workload_identity_pool_provider" "tfe-pool-provider" {
  project                            = module.project.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.tfe-pool.workload_identity_pool_id
  workload_identity_pool_provider_id = var.workload_identity_pool_provider_id
  display_name                       = "TFE Pool Provider"
  description                        = "OIDC identity pool provider for TFE Integration"
  # Use condition to make sure only token generated for a specific TFE Org and workspace can be used
  attribute_condition = "attribute.terraform_workspace_id == \"${var.tfe_workspace_id}\" && attribute.terraform_organization_id == \"${var.tfe_organization_id}\""
  attribute_mapping = {
    "google.subject"                      = "assertion.sub"
    "attribute.terraform_organization_id" = "assertion.terraform_organization_id"
    "attribute.terraform_workspace_id"    = "assertion.terraform_workspace_id"
  }
  oidc {
    # Should be different if self hosted TFE instance is used
    issuer_uri = var.issuer_uri
  }
}

###############################################################################
#                       Service Account and IAM bindings                      #
###############################################################################

module "sa-tfe" {
  source     = "../../../../modules/iam-service-account"
  project_id = module.project.project_id
  name       = "sa-tfe"

  iam = {
    "roles/iam.workloadIdentityUser" = ["principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.tfe-pool.name}/*"]
  }

  iam_project_roles = {
    "${module.project.project_id}" = [
      "roles/storage.admin"
    ]
  }
}