/**
 * Copyright 2022 Google LLC
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

# tfdoc:file:description Folder-level organization policies.

resource "google_folder_organization_policy" "boolean" {
  for_each   = var.policy_boolean
  folder     = local.folder.name
  constraint = each.key

  dynamic "boolean_policy" {
    for_each = each.value == null ? [] : [each.value]
    iterator = policy
    content {
      enforced = policy.value
    }
  }

  dynamic "restore_policy" {
    for_each = each.value == null ? [""] : []
    content {
      default = true
    }
  }
}

resource "google_folder_organization_policy" "list" {
  for_each   = var.policy_list
  folder     = local.folder.name
  constraint = each.key

  dynamic "list_policy" {
    for_each = each.value.status == null ? [] : [each.value]
    iterator = policy
    content {
      inherit_from_parent = policy.value.inherit_from_parent
      suggested_value     = policy.value.suggested_value
      dynamic "allow" {
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
      dynamic "deny" {
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

  dynamic "restore_policy" {
    for_each = each.value.status == null ? [true] : []
    content {
      default = true
    }
  }
}
