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
  # hierarchy types
  # ENV, TEAM_ENV, ENV_DIV_TEAM, DIV_TEAM_ENV
  # parse raw data from JSON files if they exist
  _cl_data_raw = (
    var.factories_config.checklist_data == null
    ? null
    : yamldecode(file(pathexpand(var.factories_config.checklist_data)))
  )
  # check that version and organization id are fine
  _cl_data = local._cl_data_raw == null ? null : (
    local._cl_data_raw.version != "0.1.0"
    ||
    local._cl_data_raw.organization.id != tostring(var.organization.id)
    ? null
    : local._cl_data_raw
  )
  # normalize hierarchy nodes, we ignore projects as
  # a) we have a project factory, b) they don't use a naming convention
  _cl_hierarchy = local._cl_data == null ? {} : {
    for v in local._cl_data.folders : v.reference_id => {
      name      = v.display_name
      parent_id = v.parent
    }
  }
  # compile the final data structure we will consume from various places
  checklist = {
  }
}
