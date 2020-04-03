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

