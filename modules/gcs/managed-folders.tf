/**
 * Copyright 2025 Google LLC
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
  # ensure all keys end with / as required by
  # google_storage_managed_folder
  managed_folders = {
    for k, v in var.managed_folders :
    (endswith(k, "/") ? k : "${k}/") => v
  }
  managed_folder_iam = flatten([
    for k, v in local.managed_folders : [
      for role, members in v.iam : {
        managed_folder = k
        role           = role
        members        = members
      }
    ]
  ])
  managed_folder_iam_bindings = merge([
    for k, v in local.managed_folders : {
      for binding_key, data in v.iam_bindings :
      "${k}${binding_key}" => {
        managed_folder = k
        role           = data.role
        members        = data.members
        condition      = data.condition
      }
    }
  ]...)
  managed_folder_iam_bindings_additive = merge([
    for k, v in local.managed_folders : {
      for binding_key, data in v.iam_bindings_additive :
      "${k}${binding_key}" => {
        managed_folder = k
        role           = data.role
        member         = data.member
        condition      = data.condition
      }
    }
  ]...)
}


resource "google_storage_managed_folder" "folder" {
  for_each      = local.managed_folders
  bucket        = local.bucket.name
  name          = each.key
  force_destroy = each.value.force_destroy
}

resource "google_storage_managed_folder_iam_binding" "authoritative" {
  for_each = {
    for binding in local.managed_folder_iam :
    "${binding.managed_folder}${binding.role}" => binding
  }
  role = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  members = [
    for v in each.value.members : lookup(local.ctx.iam_principals, v, v)
  ]
  bucket         = local.bucket.name
  managed_folder = google_storage_managed_folder.folder[each.value.managed_folder].name
}

resource "google_storage_managed_folder_iam_binding" "bindings" {
  for_each = local.managed_folder_iam_bindings
  role     = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  members = [
    for v in each.value.members : lookup(local.ctx.iam_principals, v, v)
  ]
  bucket         = local.bucket.name
  managed_folder = google_storage_managed_folder.folder[each.value.managed_folder].name

  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = each.value.condition.expression
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

resource "google_storage_managed_folder_iam_member" "members" {
  for_each       = local.managed_folder_iam_bindings_additive
  role           = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  member         = lookup(local.ctx.iam_principals, each.value.member, each.value.member)
  bucket         = local.bucket.name
  managed_folder = google_storage_managed_folder.folder[each.value.managed_folder].name

  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = each.value.condition.expression
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}
