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

locals {
  second_level_unique_names = formatlist("${var.top_level_folder_name}-%s", var.second_level_folders_names)
}

###############################################################################
#                        Terraform resources                                  #
###############################################################################

# Per second-level folder service accounts

module "service-accounts-tf-second-level-folders" {
  source             = "terraform-google-modules/service-accounts/google"
  version            = "2.0.0"
  project_id         = var.tf_project_id
  org_id             = var.organization_id
  billing_account_id = var.billing_account_id
  prefix             = var.prefix
  names              = local.second_level_unique_names
  grant_billing_role = true
  grant_xpn_roles    = false
  generate_keys      = var.generate_service_account_keys
}

# Per second-level folders Terraform state GCS buckets

module "gcs-tf-second-level-folders" {
  source          = "terraform-google-modules/cloud-storage/google"
  version         = "1.0.0"
  project_id      = var.tf_project_id
  prefix          = "${var.prefix}-tf"
  names           = local.second_level_unique_names
  location        = var.gcs_location
  set_admin_roles = true
  bucket_admins = zipmap(
    local.second_level_unique_names,
    module.service-accounts-tf-second-level-folders.iam_emails_list
  )
}

###############################################################################
#                              Top-level folder                               #
###############################################################################

module "top-level-folder" {
  source  = "terraform-google-modules/folders/google"
  version = "2.0.0"
  parent  = var.root_node
  names   = [var.top_level_folder_name]
}

###############################################################################
#                              Second-level folders                           #
###############################################################################

module "second-level-folders" {
  source            = "terraform-google-modules/folders/google"
  version           = "2.0.0"
  parent            = module.top-level-folder.id
  names             = var.second_level_folders_names
  set_roles         = true
  per_folder_admins = module.service-accounts-tf-second-level-folders.iam_emails_list
  folder_admin_roles = [
    "roles/resourcemanager.folderViewer",
    "roles/resourcemanager.projectCreator",
    "roles/owner",
    "roles/compute.networkAdmin",
    "roles/compute.xpnAdmin"
  ]
}