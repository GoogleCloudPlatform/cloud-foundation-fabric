/**
 * Copyright 2024 Google LLC
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

# tfdoc:file:description Security stage resources.

locals {
  # FAST-specific IAM
  _security_folder_fast_iam = {
    "roles/logging.admin"                  = [module.branch-security-sa.iam_email]
    "roles/owner"                          = [module.branch-security-sa.iam_email]
    "roles/resourcemanager.folderAdmin"    = [module.branch-security-sa.iam_email]
    "roles/resourcemanager.projectCreator" = [module.branch-security-sa.iam_email]
    # read-only (plan) automation service account
    "roles/viewer"                       = [module.branch-security-r-sa.iam_email]
    "roles/resourcemanager.folderViewer" = [module.branch-security-r-sa.iam_email]
  }

  # deep-merge FAST-specific IAM with user-provided bindings in var.folder_iam
  _security_folder_iam = merge(
    var.folder_iam.security,
    {
      for role, principals in local._security_folder_fast_iam :
      role => distinct(concat(principals, lookup(var.folder_iam.security, role, [])))
    }
  )
}

module "branch-security-folder" {
  source = "../../../modules/folder"
  parent = local.root_node
  name   = "Security"
  iam_by_principals = {
    (local.principals.gcp-security-admins) = [
      # owner and viewer roles are broad and might grant unwanted access
      # replace them with more selective custom roles for production deployments
      "roles/editor"
    ]
  }
  iam = local._security_folder_iam
  iam_bindings = {
    tenant_iam_admin_conditional = {
      members = [
        module.branch-security-sa.iam_email,
      ]
      role = "roles/resourcemanager.folderIamAdmin"
      condition = {
        expression = format(
          "api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly([%s])",
          join(",", formatlist("'%s'", [
            "roles/privateca.certificateManager"
          ]))
        )
        title       = "security_sa_delegated_grants"
        description = "Certificate Authority Service delegated grants."
      }
    }
  }
  tag_bindings = {
    context = try(
      local.tag_values["${var.tag_names.context}/security"].id, null
    )
  }
}

# automation service account

module "branch-security-sa" {
  source                 = "../../../modules/iam-service-account"
  project_id             = var.automation.project_id
  name                   = "prod-resman-sec-0"
  display_name           = "Terraform resman security service account."
  prefix                 = var.prefix
  service_account_create = var.root_node == null
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.branch-security-sa-cicd[0].iam_email, null)
    ])
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectAdmin"]
  }
}

# automation read-only service account

module "branch-security-r-sa" {
  source                 = "../../../modules/iam-service-account"
  project_id             = var.automation.project_id
  name                   = "prod-resman-sec-0r"
  display_name           = "Terraform resman security service account (read-only)."
  prefix                 = var.prefix
  service_account_create = var.root_node == null
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.branch-security-r-sa-cicd[0].iam_email, null)
    ])
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = [var.custom_roles["storage_viewer"]]
  }
}

# automation bucket

module "branch-security-gcs" {
  source     = "../../../modules/gcs"
  project_id = var.automation.project_id
  name       = "prod-resman-sec-0"
  prefix     = var.prefix
  location   = var.locations.gcs
  versioning = true
  iam = {
    "roles/storage.objectAdmin"  = [module.branch-security-sa.iam_email]
    "roles/storage.objectViewer" = [module.branch-security-r-sa.iam_email]
  }
}
