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
    BILLING_ADMINS = local.groups.gcp-billing-admins
    DEVOPS         = local.groups.gcp-devops
    # LOGGING_ADMINS
    # MONITORING_ADMINS
    NETWORK_ADMINS  = local.groups.gcp-network-admins
    ORG_ADMINS      = local.groups.gcp-organization-admins
    SECURITY_ADMINS = local.groups.gcp-security-admins
  }
  # parse raw data from JSON files if they exist
  _cl_data_raw = (
    var.factories_config.checklist_data == null
    ? null
    : jsondecode(file(pathexpand(var.factories_config.checklist_data)))
  )
  _cl_org_iam_raw = (
    var.factories_config.checklist_org_iam == null
    ? null
    : jsondecode(file(pathexpand(var.factories_config.checklist_org_iam)))
  )
  # check that version and organization id are fine
  _cl_data = local._cl_data_raw == null ? null : (
    local._cl_data_raw.version != "0.1.0"
    ||
    local._cl_data_raw.organization.id != tostring(var.organization.id)
    ? null
    : local._cl_data_raw
  )
  _cl_org_iam = local._cl_org_iam_raw == null ? null : (
    local._cl_org_iam_raw.version != "0.1.0"
    ||
    local._cl_org_iam_raw.organization.id != tostring(var.organization.id)
    ? null
    : local._cl_org_iam_raw.iam_bindings
  )
  # do a first pass on IAM bindings to identify groups and normalize
  _cl_org_iam_bindings = local._cl_org_iam == null ? {} : {
    for b in local._cl_org_iam :
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
    billing_account = (
      local._cl_data == null ? null : local._cl_data.billing_account
    )
    group_iam = {
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
            key    = v.is_group ? "${r}-group:${k}" : "${r}-${k}"
            member = v.is_group ? "group:${k}" : k
            role   = r
          }
        ]
      ]
    ]))
    location = (
      local._cl_data == null
      ? null
      : try(local._cl_data_raw.logging.sinks[0].destination.location, null)
    )
  }
}
