# Copyright 2019 Google LLC
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
#                        Terraform top-level resources                        #
###############################################################################

# Terraform project

module "project-tf" {
  # source          = "terraform-google-modules/project-factory/google//modules/fabric-project"
  # version         = "3.0.1"
  source          = "github.com/terraform-google-modules/terraform-google-project-factory//modules/fabric-project?ref=32a539a"
  parent_type     = var.root_type
  parent_id       = var.org_id
  billing_account = var.billing_account_id
  prefix          = var.prefix
  name            = "terraform"
  lien_reason     = "terraform"
  owners          = var.terraform_owners
  activate_apis   = var.project_services
}

# per-environment service accounts

module "service-accounts-tf-environments" {
  # source             = "terraform-google-modules/service-accounts/google"
  # version            = "1.0.1"
  source             = "github.com/terraform-google-modules/terraform-google-service-accounts?ref=857f394"
  project_id         = module.project-tf.project_id
  org_id             = var.org_id
  billing_account_id = var.billing_account_id
  prefix             = var.prefix
  names              = var.environments
  grant_billing_role = true
  grant_xpn_roles    = true
  generate_keys      = true
}

# bootstrap Terraform state  GCS bucket

module "gcs-tf-bootstrap" {
  # source        = "terraform-google-modules/cloud-storage/google"
  # version       = "1.0.0"
  source     = "github.com/terraform-google-modules/terraform-google-cloud-storage?ref=e7243fd"
  project_id = module.project-tf.project_id
  prefix     = "${var.prefix}-tf"
  names      = ["tf-bootstrap"]
  location   = var.gcs_location
}

# per-environment Terraform state GCS buckets

module "gcs-tf-environments" {
  # source        = "terraform-google-modules/cloud-storage/google"
  # version       = "1.0.0"
  source          = "github.com/terraform-google-modules/terraform-google-cloud-storage?ref=e7243fd"
  project_id      = module.project-tf.project_id
  prefix          = "${var.prefix}-tf"
  names           = var.environments
  location        = var.gcs_location
  set_admin_roles = true
  bucket_admins = zipmap(
    var.environments,
    module.service-accounts-tf-environments.iam_emails
  )
}

###############################################################################
#                              Top-level folders                              #
###############################################################################

# TODO(ludomagno): move XPN admin role here after checking it now works on folders

module "folders-top-level" {
  source            = "terraform-google-modules/folders/google"
  version           = "1.0.0"
  parent_type       = var.root_type
  parent_id         = var.org_id
  names             = var.environments
  set_roles         = true
  per_folder_admins = module.service-accounts-tf-environments.iam_emails
  folder_admin_roles = [
    "roles/resourcemanager.folderViewer",
    "roles/resourcemanager.projectCreator",
    "roles/owner",
    "roles/compute.networkAdmin",
  ]
}
