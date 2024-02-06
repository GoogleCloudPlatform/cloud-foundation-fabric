# Copyright 2023 Google LLC
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

module "host-project" {
  source = "../../../../modules/project"
  billing_account = (var.project_create != null
    ? var.project_create.billing_account_id
    : null
  )
  name = var.project_name
  parent = (
    var.project_create != null
    ? var.project_create.parent
    : null
  )
  services = [
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "servicemanagement.googleapis.com",
    "servicecontrol.googleapis.com",
    "vmmigration.googleapis.com",
  ]
  project_create = var.project_create != null
  iam_bindings_additive = {
    admin_sa_key_admin = {
      role   = "roles/iam.serviceAccountKeyAdmin"
      member = var.migration_admin
    }
    admin_sa_creator = {
      role   = "roles/iam.serviceAccountCreator"
      member = var.migration_admin
    }
    admin_vmm_admin = {
      role   = "roles/vmmigration.admin"
      member = var.migration_admin
    }
    viewer_vmm_viewer = {
      role   = "roles/vmmigration.viewer"
      member = var.migration_viewer
    }
  }
}

module "m4ce-service-account" {
  source       = "../../../../modules/iam-service-account"
  project_id   = module.host-project.project_id
  name         = "m4ce-sa"
  generate_key = true
}

module "target-projects" {
  for_each       = toset(var.migration_target_projects)
  source         = "../../../../modules/project"
  name           = each.key
  project_create = false
  services = [
    "servicemanagement.googleapis.com",
    "servicecontrol.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com"
  ]
  iam_bindings_additive = {
    admin_project_iam_admin = {
      role   = "roles/resourcemanager.projectIamAdmin"
      member = var.migration_admin
    }
    admin_compute_viewer = {
      role   = "roles/compute.viewer"
      member = var.migration_admin
    }
    admin_sa_user = {
      role   = "roles/iam.serviceAccountUser"
      member = var.migration_admin
    }
  }
}
