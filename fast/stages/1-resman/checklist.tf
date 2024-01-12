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
  # parse raw data from JSON files if they exist
  _cl_data = (
    var.factories_config.checklist_data == null
    ? null
    : jsondecode(file(pathexpand(var.factories_config.checklist_data)))
  )

  # normalized IAM bindings one element per binding
  _cl_iam = local._cl_data == null ? [] : flatten([
    for v in try(local._cl_data.access_control, []) : [
      for r in v.role : {
        principal   = v.principal
        resource_id = v.resource.id
        role        = r
      } if v.resource.type == "FOLDER"
    ]
  ])
  # compile the final data structure we will consume from various places
  checklist = {
    hierarchy = local._cl_data == null ? {} : {
      for v in try(local._cl_data.folders, []) : v.reference_id => {
        level     = length(split("/", v.reference_id))
        name      = v.display_name
        parent_id = v.parent
      }
    }
    iam = {
      for v in local._cl_iam : v.resource_id => v...
    }
  }
}

check "checklist" {
  assert {
    condition = (
      var.factories_config.checklist_data == null
      ) || (
      try(local._cl_data.version, "") == "0.1.0"
    )
    error_message = join("", [
      "Checklist file version must be 0.1.0. ",
      "File ${coalesce(var.factories_config.checklist_data, "NULL")} has version ${try(local._cl_data.version, "NULL")}.",
    ])
  }

  assert {
    condition = (
      var.factories_config.checklist_data == null
      ) || (
      try(local._cl_data.organization.id, null) == tostring(var.organization.id)
    )
    error_message = join("", [
      "Organization Id doesn't match. var.organization.id is ${var.organization.id}. ",
      "File ${coalesce(var.factories_config.checklist_data, "NULL")} has organization ${try(local._cl_data.organization.id, "NULL")}.",
    ])
  }
}

module "checklist-folder-1" {
  source = "../../../modules/folder"
  for_each = {
    for k, v in local.checklist.hierarchy : k => v if v.level == 1
  }
  parent = "organizations/${var.organization.id}"
  name   = each.value.name
  iam = {
    for v in try(local.checklist.iam[each.key], []) :
    v.role => v.principal...
  }
}

module "checklist-folder-2" {
  source = "../../../modules/folder"
  for_each = {
    for k, v in local.checklist.hierarchy : k => v if v.level == 2
  }
  parent = module.checklist-folder-1[each.value.parent_id].id
  name   = each.value.name
  iam = {
    for v in try(local.checklist.iam[each.key], []) :
    v.role => v.principal...
  }
}

module "checklist-folder-3" {
  source = "../../../modules/folder"
  for_each = {
    for k, v in local.checklist.hierarchy : k => v if v.level == 3
  }
  parent = module.checklist-folder-2[each.value.parent_id].id
  name   = each.value.name
  iam = {
    for v in try(local.checklist.iam[each.key], []) :
    v.role => v.principal...
  }
}
