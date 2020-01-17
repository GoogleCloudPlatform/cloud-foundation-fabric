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
  folders = [for name in var.names : google_folder.folders[name]]
  iam_pairs = flatten([
    for name, roles in var.iam_roles :
    [for role in roles : { name = name, role = role }]
  ])
  iam_keypairs = {
    for pair in local.iam_pairs :
    "${pair.name}-${pair.role}" => pair
  }
}

resource "google_folder" "folders" {
  for_each     = toset(var.names)
  display_name = each.value
  parent       = var.parent
}

# give project creation access to service accounts
# https://cloud.google.com/resource-manager/docs/access-control-folders#granting_folder-specific_roles_to_enable_project_creation
# - external users need to have accepted the invitation email to join
# "roles/owner",
# "roles/resourcemanager.folderViewer",
# "roles/resourcemanager.projectCreator",
# "roles/compute.networkAdmin",


resource "google_folder_iam_binding" "authoritative" {
  for_each = local.iam_keypairs
  folder   = google_folder.folders[each.value.name].name
  role     = each.value.role
  members = lookup(
    lookup(var.iam_members, each.value.name, {}), each.value.role, []
  )
}

# resource "google_folder_iam_member" "non_authoritative" {
#   for_each = length(var.iam_non_authoritative_roles) > 0 ? local.iam_non_authoritative : {}
#   folder  = google_project.project.project_id
#   role     = each.value.role
#   member   = each.value.member
# }
