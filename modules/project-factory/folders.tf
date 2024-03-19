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

# tfdoc:file:description Folder hierarchy factory resources.

module "hierarchy-folder-lvl-1" {
  source   = "../folder"
  for_each = { for k, v in local.folders : k => v if v.level == 1 }
  parent = try(
    # allow the YAML data to set the parent for this level
    lookup(
      var.factories_config.hierarchy.parent_ids,
      each.value.parent,
      # use the value as is if it's not in the parents map
      each.value.parent
    ),
    # use the default value in the initial parents map
    var.factories_config.hierarchy.parent_ids.default
    # fail if we don't have an explicit parent
  )
  name                  = each.value.name
  iam                   = lookup(each.value, "iam", {})
  iam_bindings          = lookup(each.value, "iam_bindings", {})
  iam_bindings_additive = lookup(each.value, "iam_bindings_additive", {})
  iam_by_principals     = lookup(each.value, "iam_by_principals", {})
  org_policies          = lookup(each.value, "org_policies", {})
  tag_bindings          = lookup(each.value, "tag_bindings", {})
}

module "hierarchy-folder-lvl-2" {
  source                = "../folder"
  for_each              = { for k, v in local.folders : k => v if v.level == 2 }
  parent                = module.hierarchy-folder-lvl-1[each.value.parent_key].id
  name                  = each.value.name
  iam                   = lookup(each.value, "iam", {})
  iam_bindings          = lookup(each.value, "iam_bindings", {})
  iam_bindings_additive = lookup(each.value, "iam_bindings_additive", {})
  iam_by_principals     = lookup(each.value, "iam_by_principals", {})
  org_policies          = lookup(each.value, "org_policies", {})
  tag_bindings          = lookup(each.value, "tag_bindings", {})
}

module "hierarchy-folder-lvl-3" {
  source                = "../folder"
  for_each              = { for k, v in local.folders : k => v if v.level == 3 }
  parent                = module.hierarchy-folder-lvl-2[each.value.parent_key].id
  name                  = each.value.name
  iam                   = lookup(each.value, "iam", {})
  iam_bindings          = lookup(each.value, "iam_bindings", {})
  iam_bindings_additive = lookup(each.value, "iam_bindings_additive", {})
  iam_by_principals     = lookup(each.value, "iam_by_principals", {})
  org_policies          = lookup(each.value, "org_policies", {})
  tag_bindings          = lookup(each.value, "tag_bindings", {})
}
