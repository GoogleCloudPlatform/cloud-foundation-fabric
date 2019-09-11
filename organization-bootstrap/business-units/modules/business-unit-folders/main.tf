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
#                              Business Unit Folder                           #
###############################################################################

module "business-unit-folder" {
  source  = "terraform-google-modules/folders/google"
  version = "2.0.0"
  parent  = var.root_node
  names   = [var.business_unit_folder_name]
}

###############################################################################
#                              Environment Folders                            #
###############################################################################

module "environment-folders" {
  source            = "terraform-google-modules/folders/google"
  version           = "2.0.0"
  parent            = module.business-unit-folder.id
  names             = var.environments
  set_roles         = true
  per_folder_admins = var.per_folder_admins
  folder_admin_roles = [
    "roles/resourcemanager.folderViewer",
    "roles/resourcemanager.projectCreator",
    "roles/owner",
    "roles/compute.networkAdmin",
    "roles/compute.xpnAdmin"
  ]
}