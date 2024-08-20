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

locals {
  folder_parent_default = try(
    var.factories_config.context.folder_ids.default, null
  )
}

module "hierarchy-folder-lvl-1" {
  source   = "../folder"
  for_each = { for k, v in local.folders : k => v if v.level == 1 }
  parent = try(
    # allow the YAML data to set the parent for this level
    lookup(
      var.factories_config.context.folder_ids,
      each.value.parent,
      each.value.parent
    ),
    # use the default value in the initial parents map
    local.folder_parent_default
    # fail if we don't have an explicit parent
  )
  name = each.value.name
  iam = {
    for k, v in lookup(each.value, "iam", {}) : k => [
      # don't interpolate automation service account to prevent cycles
      for vv in v : lookup(
        var.factories_config.context.iam_principals, vv, vv
      )
    ]
  }
  iam_bindings = {
    for k, v in lookup(each.value, "iam_bindings", {}) : k => merge(v, {
      members = [
        # don't interpolate automation service account to prevent cycles
        for vv in v.members : lookup(
          var.factories_config.context.iam_principals, vv, vv
        )
      ]
    })
  }
  iam_bindings_additive = {
    for k, v in lookup(each.value, "iam_bindings_additive", {}) : k => merge(v, {
      # don't interpolate automation service account to prevent cycles
      member = lookup(
        var.factories_config.context.iam_principals, v.member, v.member
      )
    })
  }
  iam_by_principals = lookup(each.value, "iam_by_principals", {})
  org_policies      = lookup(each.value, "org_policies", {})
  tag_bindings = {
    for k, v in lookup(each.value, "tag_bindings", {}) :
    k => lookup(var.factories_config.context.tag_values, v, v)
  }
}

module "hierarchy-folder-lvl-2" {
  source   = "../folder"
  for_each = { for k, v in local.folders : k => v if v.level == 2 }
  parent   = module.hierarchy-folder-lvl-1[each.value.parent_key].id
  name     = each.value.name
  iam = {
    for k, v in lookup(each.value, "iam", {}) : k => [
      # don't interpolate automation service account to prevent cycles
      for vv in v : lookup(
        var.factories_config.context.iam_principals, vv, vv
      )
    ]
  }
  iam_bindings = {
    for k, v in lookup(each.value, "iam_bindings", {}) : k => merge(v, {
      members = [
        # don't interpolate automation service account to prevent cycles
        for vv in v.members : lookup(
          var.factories_config.context.iam_principals, vv, vv
        )
      ]
    })
  }
  iam_bindings_additive = {
    for k, v in lookup(each.value, "iam_bindings_additive", {}) : k => merge(v, {
      # don't interpolate automation service account to prevent cycles
      member = lookup(
        var.factories_config.context.iam_principals, v.member, v.member
      )
    })
  }
  iam_by_principals = lookup(each.value, "iam_by_principals", {})
  org_policies      = lookup(each.value, "org_policies", {})
  tag_bindings = {
    for k, v in lookup(each.value, "tag_bindings", {}) :
    k => lookup(var.factories_config.context.tag_values, v, v)
  }
}

module "hierarchy-folder-lvl-3" {
  source   = "../folder"
  for_each = { for k, v in local.folders : k => v if v.level == 3 }
  parent   = module.hierarchy-folder-lvl-2[each.value.parent_key].id
  name     = each.value.name
  iam = {
    for k, v in lookup(each.value, "iam", {}) : k => [
      # don't interpolate automation service account to prevent cycles
      for vv in v : lookup(
        var.factories_config.context.iam_principals, vv, vv
      )
    ]
  }
  iam_bindings = {
    for k, v in lookup(each.value, "iam_bindings", {}) : k => merge(v, {
      members = [
        # don't interpolate automation service account to prevent cycles
        for vv in v.members : lookup(
          var.factories_config.context.iam_principals, vv, vv
        )
      ]
    })
  }
  iam_bindings_additive = {
    for k, v in lookup(each.value, "iam_bindings_additive", {}) : k => merge(v, {
      # don't interpolate automation service account to prevent cycles
      member = lookup(
        var.factories_config.context.iam_principals, v.member, v.member
      )
    })
  }
  iam_by_principals = lookup(each.value, "iam_by_principals", {})
  org_policies      = lookup(each.value, "org_policies", {})
  tag_bindings = {
    for k, v in lookup(each.value, "tag_bindings", {}) :
    k => lookup(var.factories_config.context.tag_values, v, v)
  }
}
