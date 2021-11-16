/**
 * Copyright 2021 Google LLC
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
  groups_processed = flatten([for env in var.environments : [for group, members in var.groups : {
    "id"          = "${env}-${group}"
    "group"       = group
    "environment" = env
    "group_key"   = format("%s%s", replace(replace(replace(var.group_format, "%project%", var.project_id), "%env%", env), "%group%", group), var.domain != "" ? format("@%s", var.domain) : "")
    "members"     = members
    }
  ]])
  groups = { for group in local.groups_processed : group.id => group }
  members = merge(flatten([for id, group in local.groups : [{ for member in group.members : "${id}-${member}" => {
    "group_key" = group.group_key
    "group_id"  = group.id
    "member"    = format("%s%s", member, var.domain != "" ? format("@%s", var.domain) : "")
    }
  }]])...)
  groups_for_permissions = { for group, members in var.groups : group => group }
  project_permissions    = { for group, settings in var.groups_permissions : group => lookup(settings, "commonIamPermissions", lookup(settings, "projectIamPermissions", [])) }
  group_permissions      = { for group, members in var.groups : group => lookup(var.groups_permissions[group], "commonIamPermissions", lookup(var.groups_permissions[group], "projectIamPermissions", [])) }
  compute_sa_permissions = { for group, settings in var.groups_permissions : group => lookup(settings, "computeDefaultSAPermissions", []) }
  project_sa_permissions = { for group, settings in var.groups_permissions : group => lookup(settings, "projectDefaultSAPermissions", []) }
  main_group             = { for env in var.environments : env => format("%s%s", replace(replace(replace(var.group_format, "%project%", var.project_id), "%env%", env), "%group%", var.main_group), var.domain != "" ? format("@%s", var.domain) : "") }
  owner_group            = var.owner_group == "" || (var.owner == "" && length(var.owners) == 0) ? {} : { for env in var.environments : env => format("%s%s", replace(replace(replace(var.group_format, "%project%", var.project_id), "%env%", env), "%group%", var.owner_group), var.domain != "" ? format("@%s", var.domain) : "") }
  owner                  = var.owner == "" ? "" : format("%s%s", var.owner, var.domain != "" ? format("@%s", var.domain) : "")
  owners                 = length(var.owners) > 0 ? [for owner in var.owners : format("%s%s", owner, var.domain != "" ? format("@%s", var.domain) : "")] : [local.owner]
  owners_sp              = setproduct(var.environments, local.owners)
  owners_foreach         = { for k in local.owners_sp : format("%s-%s", k[0], k[1]) => [k[0], k[1]] }
  environments           = length(var.groups) > 0 ? var.environments : []
}

/**
 * Create project groups for different access groups
 */
resource "google_cloud_identity_group" "project_groups" {
  provider = google-beta
  for_each = var.only_add_permissions ? {} : local.groups

  display_name = format("%s: %s (%s)", title(each.value.group), var.project_id, upper(each.value.environment))

  parent = format("customers/%s", var.customer_id)

  group_key {
    id = each.value.group_key
  }

  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }
}

/**
 * Add members to project groups
 */
resource "google_cloud_identity_group_membership" "project_groups_membership" {
  provider = google-beta
  for_each = var.only_add_permissions || local.members == null ? {} : local.members

  group = google_cloud_identity_group.project_groups[each.value.group_id].id

  member_key {
    id = each.value.member
  }

  roles {
    name = "MEMBER"
  }
}

/**
 * Add IAM permissions to project groups
 */
module "iam" {
  for_each = local.group_permissions
  source   = "../iam/"

  domain       = var.domain
  group_format = var.group_format

  project_ids_full = var.project_ids_full
  project_id       = var.project_id
  environments     = var.environments

  group = local.groups_for_permissions[each.key]

  project_permissions = each.value
  extra_permissions   = lookup(var.groups_permissions[each.key], "perEnvironmentIamPermissions", {}) != {} ? lookup(var.groups_permissions[each.key].perEnvironmentIamPermissions, var.folder, {}) : {}

  service_accounts       = var.service_accounts
  compute_sa_permissions = local.compute_sa_permissions[each.key]
  project_sa_permissions = local.project_sa_permissions[each.key]

  additional_roles        = lookup(var.additional_roles, each.key, [])
  additional_roles_config = merge(lookup(var.additional_roles_config, "_common", {}), lookup(var.additional_roles_config, each.key, {}))
  additional_iam_roles    = lookup(var.additional_iam_roles, each.key, [])

  depends_on = [google_cloud_identity_group.project_groups]
}

/**
 * Create the main group, which is a convienience group for all project members
 */
resource "google_cloud_identity_group" "project_main_group" {
  provider = google-beta
  for_each = var.only_add_permissions ? toset([]) : toset(var.environments)

  display_name = format("%s (%s)", var.project_id, upper(each.value))

  parent = format("customers/%s", var.customer_id)

  group_key {
    id = local.main_group[each.value]
  }

  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }
}

/** 
 * Add created groups to a convenience group that contains all members
 * of the project.
 */
resource "google_cloud_identity_group_membership" "project_main_group_membership" {
  provider = google-beta
  for_each = var.only_add_permissions ? {} : local.groups

  group = google_cloud_identity_group.project_main_group[each.value.environment].id

  member_key {
    id = google_cloud_identity_group.project_groups[each.value.id].group_key[0].id
  }

  roles {
    name = "MEMBER"
  }
}

/**
 * Create the owner group, which is a convienience group for the project owner
 */
resource "google_cloud_identity_group" "project_owner_group" {
  provider = google-beta
  for_each = var.only_add_permissions ? {} : local.owner_group

  display_name = format("Owners: %s (%s)", var.project_id, upper(each.key))

  parent = format("customers/%s", var.customer_id)

  group_key {
    id = each.value
  }

  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }
}

resource "google_cloud_identity_group_membership" "project_owner_group_membership" {
  provider = google-beta
  for_each = var.only_add_permissions ? {} : local.owners_foreach

  group = google_cloud_identity_group.project_owner_group[each.value[0]].id

  member_key {
    id = each.value[1]
  }

  roles {
    name = "MEMBER"
  }
}

/** 
 * Add created groups to the Shared VPC group that has the necessary permissions on the 
 * Shared VPC host project
 */
locals {
  filtered_shared_vpc_groups = { for env in local.environments : env => var.shared_vpc_groups[env] if var.shared_vpc_groups[env] != "" }
  svpc_group_ids             = { for env, svpc_group in local.filtered_shared_vpc_groups : env => lookup(var.all_groups, format("%s%s", svpc_group, var.domain != "" ? format("@%s", var.domain) : ""), "") }
  svpc_groups                = { for group in local.groups_processed : group.id => group if var.shared_vpc_groups[group.environment] != "" }
}

# Add Shared VPC group membership
resource "google_cloud_identity_group_membership" "shared_vpc_group_membership" {
  provider = google-beta
  for_each = var.only_add_permissions ? {} : length(local.filtered_shared_vpc_groups) > 0 ? local.svpc_groups : {}

  group = local.svpc_group_ids[each.value.environment]

  member_key {
    id = google_cloud_identity_group.project_groups[each.value.id].group_key[0].id
  }

  roles {
    name = "MEMBER"
  }
}
