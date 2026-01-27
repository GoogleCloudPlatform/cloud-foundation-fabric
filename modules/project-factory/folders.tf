/**
 * Copyright 2026 Google LLC
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

# TODO: folder automation

locals {
  _folders_path = try(
    pathexpand(var.factories_config.folders), null
  )
  _folders_files = try(
    fileset(local._folders_path, "**/**/.config.yaml"),
    []
  )
  _folders_raw = merge(
    var.folders,
    {
      for f in local._folders_files : dirname(f) => yamldecode(file(
        "${coalesce(local._folders_path, "-")}/${f}"
      ))
    }
  )
  ctx_folder_ids = merge(local.ctx.folder_ids, local.folder_ids)
  folder_ids = merge(
    { for k, v in module.folder-1 : k => v.id },
    { for k, v in module.folder-2 : k => v.id },
    { for k, v in module.folder-3 : k => v.id },
    { for k, v in module.folder-4 : k => v.id }
  )
  folders_input = {
    for key, data in local._folders_raw : key => merge(data, {
      key        = key
      level      = length(split("/", key))
      parent_key = dirname(key)
      # do not enforce overrides / defaults on folders
      parent = lookup(data, "parent", null)
    })
  }
}

module "folder-1" {
  source = "../folder"
  for_each = {
    for k, v in local.folders_input : k => v if v.level == 1
  }
  deletion_protection = lookup(each.value, "deletion_protection", false)
  parent              = coalesce(each.value.parent, "$folder_ids:default")
  name                = each.value.name
  factories_config = {
    org_policies           = try(each.value.factories_config.org_policies, null)
    scc_sha_custom_modules = try(each.value.factories_config.scc_sha_custom_modules, null)
  }
  org_policies     = lookup(each.value, "org_policies", {})
  pam_entitlements = lookup(each.value, "pam_entitlements", {})
  tag_bindings     = lookup(each.value, "tag_bindings", {})
  context          = local.ctx
}

module "folder-1-iam" {
  source = "../folder"
  for_each = {
    for k, v in local.folders_input : k => v if v.level == 1
  }
  id = module.folder-1[each.key].id
  factories_config = {
    # we do anything that can refer to IAM and custom roles in this call
    pam_entitlements = try(each.value.factories_config.pam_entitlements, null)
  }
  folder_create                 = false
  autokey_config                = lookup(each.value, "autokey_config", null)
  iam                           = lookup(each.value, "iam", {})
  iam_bindings                  = lookup(each.value, "iam_bindings", {})
  iam_bindings_additive         = lookup(each.value, "iam_bindings_additive", {})
  iam_by_principals             = lookup(each.value, "iam_by_principals", {})
  iam_by_principals_conditional = lookup(each.value, "iam_by_principals_conditional", {})
  logging_data_access           = lookup(each.value, "data_access_logs", {})
  context = merge(local.ctx, {
    iam_principals = merge(
      local.ctx_iam_principals,
      lookup(local.self_sas_iam_emails, each.key, {}),
      local.projects_service_agents
    )
    project_ids     = local.ctx_project_ids
    project_numbers = local.ctx_project_numbers
  })
}

module "folder-2" {
  source = "../folder"
  for_each = {
    for k, v in local.folders_input : k => v if v.level == 2
  }
  deletion_protection = lookup(each.value, "deletion_protection", false)
  parent = coalesce(
    each.value.parent, "$folder_ids:${each.value.parent_key}"
  )
  name = each.value.name
  factories_config = {
    org_policies           = try(each.value.factories_config.org_policies, null)
    scc_sha_custom_modules = try(each.value.factories_config.scc_sha_custom_modules, null)
  }
  org_policies     = lookup(each.value, "org_policies", {})
  pam_entitlements = lookup(each.value, "pam_entitlements", {})
  tag_bindings     = lookup(each.value, "tag_bindings", {})
  context = merge(local.ctx, {
    folder_ids = merge(local.ctx.folder_ids, {
      for k, v in module.folder-1 : k => v.id
    })
  })
  depends_on = [module.folder-1]
}

module "folder-2-iam" {
  source = "../folder"
  for_each = {
    for k, v in local.folders_input : k => v if v.level == 2
  }
  id = module.folder-2[each.key].id
  factories_config = {
    # we do anything that can refer to IAM and custom roles in this call
    pam_entitlements = try(each.value.factories_config.pam_entitlements, null)
  }
  folder_create                 = false
  autokey_config                = lookup(each.value, "autokey_config", null)
  iam                           = lookup(each.value, "iam", {})
  iam_bindings                  = lookup(each.value, "iam_bindings", {})
  iam_bindings_additive         = lookup(each.value, "iam_bindings_additive", {})
  iam_by_principals             = lookup(each.value, "iam_by_principals", {})
  iam_by_principals_conditional = lookup(each.value, "iam_by_principals_conditional", {})
  logging_data_access           = lookup(each.value, "data_access_logs", {})
  context = merge(local.ctx, {
    folder_ids = merge(local.ctx.folder_ids, {
      for k, v in module.folder-1 : k => v.id
    })
    iam_principals = merge(
      local.ctx_iam_principals,
      lookup(local.self_sas_iam_emails, each.key, {}),
      local.projects_service_agents
    )
    project_ids     = local.ctx_project_ids
    project_numbers = local.ctx_project_numbers
  })
}

module "folder-3" {
  source = "../folder"
  for_each = {
    for k, v in local.folders_input : k => v if v.level == 3
  }
  deletion_protection = lookup(each.value, "deletion_protection", false)
  parent = coalesce(
    each.value.parent, "$folder_ids:${each.value.parent_key}"
  )
  name = each.value.name
  factories_config = {
    org_policies           = try(each.value.factories_config.org_policies, null)
    scc_sha_custom_modules = try(each.value.factories_config.scc_sha_custom_modules, null)
  }
  org_policies     = lookup(each.value, "org_policies", {})
  pam_entitlements = lookup(each.value, "pam_entitlements", {})
  tag_bindings     = lookup(each.value, "tag_bindings", {})
  context = merge(local.ctx, {
    folder_ids = merge(local.ctx.folder_ids, {
      for k, v in module.folder-2 : k => v.id
    })
  })
  depends_on = [module.folder-2]
}

module "folder-3-iam" {
  source = "../folder"
  for_each = {
    for k, v in local.folders_input : k => v if v.level == 3
  }
  id = module.folder-3[each.key].id
  factories_config = {
    # we do anything that can refer to IAM and custom roles in this call
    pam_entitlements = try(each.value.factories_config.pam_entitlements, null)
  }
  folder_create                 = false
  autokey_config                = lookup(each.value, "autokey_config", null)
  iam                           = lookup(each.value, "iam", {})
  iam_bindings                  = lookup(each.value, "iam_bindings", {})
  iam_bindings_additive         = lookup(each.value, "iam_bindings_additive", {})
  iam_by_principals             = lookup(each.value, "iam_by_principals", {})
  iam_by_principals_conditional = lookup(each.value, "iam_by_principals_conditional", {})
  logging_data_access           = lookup(each.value, "data_access_logs", {})
  context = merge(local.ctx, {
    folder_ids = merge(local.ctx.folder_ids, {
      for k, v in module.folder-2 : k => v.id
    })
    iam_principals = merge(
      local.ctx_iam_principals,
      lookup(local.self_sas_iam_emails, each.key, {}),
      local.projects_service_agents
    )
    project_ids     = local.ctx_project_ids
    project_numbers = local.ctx_project_numbers
  })
}

module "folder-4" {
  source = "../folder"
  for_each = {
    for k, v in local.folders_input : k => v if v.level == 4
  }
  deletion_protection = lookup(each.value, "deletion_protection", false)
  parent = coalesce(
    each.value.parent, "$folder_ids:${each.value.parent_key}"
  )
  name = each.value.name
  factories_config = {
    org_policies           = try(each.value.factories_config.org_policies, null)
    scc_sha_custom_modules = try(each.value.factories_config.scc_sha_custom_modules, null)
  }
  org_policies     = lookup(each.value, "org_policies", {})
  pam_entitlements = lookup(each.value, "pam_entitlements", {})
  tag_bindings     = lookup(each.value, "tag_bindings", {})
  context = merge(local.ctx, {
    folder_ids = merge(local.ctx.folder_ids, {
      for k, v in module.folder-3 : k => v.id
    })
  })
  depends_on = [module.folder-3]
}

module "folder-4-iam" {
  source = "../folder"
  for_each = {
    for k, v in local.folders_input : k => v if v.level == 4
  }
  id = module.folder-4[each.key].id
  factories_config = {
    # we do anything that can refer to IAM and custom roles in this call
    pam_entitlements = try(each.value.factories_config.pam_entitlements, null)
  }
  folder_create                 = false
  autokey_config                = lookup(each.value, "autokey_config", null)
  iam                           = lookup(each.value, "iam", {})
  iam_bindings                  = lookup(each.value, "iam_bindings", {})
  iam_bindings_additive         = lookup(each.value, "iam_bindings_additive", {})
  iam_by_principals             = lookup(each.value, "iam_by_principals", {})
  iam_by_principals_conditional = lookup(each.value, "iam_by_principals_conditional", {})
  logging_data_access           = lookup(each.value, "data_access_logs", {})
  context = merge(local.ctx, {
    folder_ids = merge(local.ctx.folder_ids, {
      for k, v in module.folder-3 : k => v.id
    })
    iam_principals = merge(
      local.ctx_iam_principals,
      lookup(local.self_sas_iam_emails, each.key, {}),
      local.projects_service_agents
    )
    project_ids     = local.ctx_project_ids
    project_numbers = local.ctx_project_numbers
  })
}
