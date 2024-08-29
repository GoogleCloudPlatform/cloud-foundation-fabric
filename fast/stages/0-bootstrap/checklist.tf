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

locals {
  # group mapping from checklist to ours
  _cl_groups = {
    BILLING_ADMINS = local.principals.gcp-billing-admins
    DEVOPS         = local.principals.gcp-devops
    # LOGGING_ADMINS
    # MONITORING_ADMINS
    NETWORK_ADMINS  = local.principals.gcp-network-admins
    ORG_ADMINS      = local.principals.gcp-organization-admins
    SECURITY_ADMINS = local.principals.gcp-security-admins
  }
  # parse raw data from JSON files if they exist
  _cl_data_raw = (
    var.factories_config.checklist_data == null
    ? null
    : jsondecode(file(pathexpand(var.factories_config.checklist_data)))
  )
  _cl_org_raw = (
    var.factories_config.checklist_org_iam == null
    ? null
    : jsondecode(file(pathexpand(var.factories_config.checklist_org_iam)))
  )
  # check that files are for the correct organization and ignore them if not
  _cl_data = (
    try(local._cl_data_raw.cloud_setup_config.organization.id, null) != tostring(var.organization.id)
    ? null
    : local._cl_data_raw.cloud_setup_config
  )
  _cl_org = (
    try(local._cl_org_raw.cloud_setup_org_iam.organization.id, null) != tostring(var.organization.id)
    ? null
    : local._cl_org_raw.cloud_setup_org_iam
  )
  # do a first pass on IAM bindings to identify groups and normalize
  _cl_org_iam_bindings = {
    for b in try(local._cl_org.iam_bindings, []) :
    lookup(local._cl_groups, b.group_id, b.principal) => {
      additive = [
        for r in b.role : r if !contains(local.iam_roles_authoritative, r)
      ]
      authoritative = [
        for r in b.role : r if contains(local.iam_roles_authoritative, r)
      ]
      roles    = b.role
      is_group = lookup(local._cl_groups, b.group_id, null) != null
    }
  }
  # compile the final data structure we will consume from various places
  checklist = {
    billing_account = try(local._cl_data.billing_account, null)
    iam_principals = {
      for k, v in local._cl_org_iam_bindings :
      k => v.authoritative if v.is_group && length(v.authoritative) > 0
    }
    iam = {
      for k, v in local._cl_org_iam_bindings :
      k => v.authoritative if !v.is_group && length(v.authoritative) > 0
    }
    iam_bindings = concat(flatten([
      for k, v in local._cl_org_iam_bindings : [
        for r in v.additive : [
          {
            key    = "${r}-${k}"
            member = k
            role   = r
          }
        ]
      ]
    ]))
    location = try(local._cl_data.logging.sinks[0].destination.location, null)
  }
  uses_checklist = (
    var.factories_config.checklist_data != null
    ||
    var.factories_config.checklist_org_iam != null
  )
}
check "checklist" {
  # checklist data files don't need to be both present so we check independently
  # version mismatch might be ok, we just alert users
  assert {
    condition = (
      var.factories_config.checklist_data == null ||
      try(local._cl_data_raw.cloud_setup_config.version, null) == "0.1.0"
    )
    error_message = "Checklist data version mismatch."
  }
  assert {
    condition = (
      var.factories_config.checklist_org_iam == null ||
      try(local._cl_org_raw.cloud_setup_org_iam.version, null) == "0.1.0"
    )
    error_message = "Checklist org IAM version mismatch."
  }
  # wrong org id forces us to ignore the files, but we also alert users
  assert {
    condition = (
      var.factories_config.checklist_data == null ||
      try(local._cl_data_raw.cloud_setup_config.organization.id, null) == tostring(var.organization.id)
    )
    error_message = "Checklist data organization id mismatch, file ignored."
  }
  assert {
    condition = (
      var.factories_config.checklist_org_iam == null ||
      try(local._cl_org_raw.cloud_setup_org_iam.organization.id, null) == tostring(var.organization.id)
    )
    error_message = "Checklist org IAM organization id mismatch, file ignored."
  }
}

# checklist files bucket

module "automation-tf-checklist-gcs" {
  source     = "../../../modules/gcs"
  count      = local.uses_checklist ? 1 : 0
  project_id = module.automation-project.project_id
  name       = "iac-core-checklist-0"
  prefix     = local.prefix
  location   = local.locations.gcs
  versioning = true
  depends_on = [module.organization]
}

resource "google_storage_bucket_object" "checklist_data" {
  count  = var.factories_config.checklist_data != null ? 1 : 0
  bucket = module.automation-tf-checklist-gcs[0].name
  name   = "checklist/data.tfvars.json"
  source = var.factories_config.checklist_data
}

resource "google_storage_bucket_object" "checklist_org_iam" {
  count  = var.factories_config.checklist_org_iam != null ? 1 : 0
  bucket = module.automation-tf-checklist-gcs[0].name
  name   = "checklist/org-iam.tfvars.json"
  source = var.factories_config.checklist_org_iam
}
