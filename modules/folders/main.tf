/**
 * Copyright 2018 Google LLC
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
  folders = (
    local.has_folders
    ? [for name in var.names : google_folder.folders[name]]
    : []
  )
  # needed when destroying
  has_folders = length(google_folder.folders) > 0
  iam_pairs = var.iam_roles == null ? [] : flatten([
    for name, roles in var.iam_roles :
    [for role in roles : { name = name, role = role }]
  ])
  iam_keypairs = {
    for pair in local.iam_pairs :
    "${pair.name}-${pair.role}" => pair
  }
  iam_members = var.iam_members == null ? {} : var.iam_members
  policy_boolean_pairs = {
    for pair in setproduct(var.names, keys(var.policy_boolean)) :
    "${pair.0}-${pair.1}" => {
      folder      = pair.0,
      policy      = pair.1,
      policy_data = var.policy_boolean[pair.1]
    }
  }
  policy_list_pairs = {
    for pair in setproduct(var.names, keys(var.policy_list)) :
    "${pair.0}-${pair.1}" => {
      folder      = pair.0,
      policy      = pair.1,
      policy_data = var.policy_list[pair.1]
    }
  }
}

resource "google_folder" "folders" {
  for_each     = toset(var.names)
  display_name = each.value
  parent       = var.parent
}

resource "google_folder_iam_binding" "authoritative" {
  for_each = local.iam_keypairs
  folder   = google_folder.folders[each.value.name].name
  role     = each.value.role
  members = lookup(
    lookup(local.iam_members, each.value.name, {}), each.value.role, []
  )
}

resource "google_folder_organization_policy" "boolean" {
  for_each   = local.policy_boolean_pairs
  folder     = google_folder.folders[each.value.folder].id
  constraint = each.value.policy

  dynamic boolean_policy {
    for_each = each.value.policy_data == null ? [] : [each.value.policy_data]
    iterator = policy
    content {
      enforced = policy.value
    }
  }

  dynamic restore_policy {
    for_each = each.value.policy_data == null ? [""] : []
    content {
      default = true
    }
  }
}

resource "google_folder_organization_policy" "list" {
  for_each   = local.policy_list_pairs
  folder     = google_folder.folders[each.value.folder].id
  constraint = each.value.policy

  dynamic list_policy {
    for_each = each.value.policy_data.status == null ? [] : [each.value.policy_data]
    iterator = policy
    content {
      inherit_from_parent = policy.value.inherit_from_parent
      suggested_value     = policy.value.suggested_value
      dynamic allow {
        for_each = policy.value.status ? [""] : []
        content {
          values = (
            try(length(policy.value.values) > 0, false)
            ? policy.value.values
            : null
          )
          all = (
            try(length(policy.value.values) > 0, false)
            ? null
            : true
          )
        }
      }
      dynamic deny {
        for_each = policy.value.status ? [] : [""]
        content {
          values = (
            try(length(policy.value.values) > 0, false)
            ? policy.value.values
            : null
          )
          all = (
            try(length(policy.value.values) > 0, false)
            ? null
            : true
          )
        }
      }
    }
  }

  dynamic restore_policy {
    for_each = each.value.policy_data.status == null ? [true] : []
    content {
      default = true
    }
  }
}
