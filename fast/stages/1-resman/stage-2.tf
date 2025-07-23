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

# tfdoc:file:description Stage 2s locals and resources.

locals {
  # read and decode factory files
  _stage2_path = try(
    pathexpand(var.factories_config.stage_2), null
  )
  _stage2_files = try(
    fileset(local._stage2_path, "**/*.yaml"),
    []
  )
  _stage2_data = {
    for f in local._stage2_files :
    split(".", f)[0] => yamldecode(file(
      "${coalesce(local._stage2_path, "-")}/${f}"
    ))
  }
  # merge stage 2 from factory and variable data
  _stage2 = merge(
    # normalize factory data attributes with defaults and nulls
    {
      for k, v in local._stage2_data : k => {
        short_name = lookup(v, "short_name", null)
        cicd_config = lookup(v, "cicd_config", null) == null ? null : {
          identity_provider = v.cicd_config.identity_provider
          repository = merge(v.cicd_config.repository, {
            branch = try(v.cicd_config.repository.branch, null)
            type   = try(v.cicd_config.repository.type, "github")
          })
          workflows_config = {
            extra_files = try(v.cicd_config.workflows_config.extra_files, [])
          }
        }
        folder_config = lookup(v, "folder_config", null) == null ? null : {
          name                  = v.folder_config.name
          create_env_folders    = try(v.folder_config.create_env_folders, false)
          iam                   = try(v.folder_config.iam, {})
          iam_bindings          = try(v.folder_config.iam_bindings, {})
          iam_bindings_additive = try(v.folder_config.iam_bindings_additive, {})
          iam_by_principals     = try(v.folder_config.iam_by_principals, {})
          org_policies          = try(v.folder_config.org_policies, {})
          parent_id             = try(v.folder_config.parent_id, null)
          tag_bindings          = try(v.folder_config.tag_bindings, {})
        }
        organization_config = {
          iam                   = try(v.organization_config.iam, {})
          iam_bindings          = try(v.organization_config.iam_bindings, {})
          iam_bindings_additive = try(v.organization_config.iam_bindings_additive, {})
          iam_by_principals     = try(v.organization_config.iam_by_principals, {})
        }
        stage3_config = {
          iam_admin_delegated = try(v.stage3_config.iam_admin_delegated, [])
          iam_viewer          = try(v.stage3_config.iam_viewer, [])
        }
      }
    },
    var.fast_stage_2
  )
  # normalize attributes
  stage2 = {
    for k, v in local._stage2 : k => merge(v, {
      short_name = replace(coalesce(v.short_name, k), "_", "-")
      folder_config = v.folder_config == null ? null : merge(v.folder_config, {
        iam = {
          for kk, vv in v.folder_config.iam : kk => [
            for m in vv : contains(["ro", "rw"], m) ? "${k}-${m}" : m
          ]
        }
        iam_bindings = {
          for kk, vv in v.folder_config.iam_bindings :
          kk => {
            role = vv.role
            members = [
              for m in vv.members : contains(["ro", "rw"], m) ? "${k}-${m}" : m
            ]
            condition = lookup(vv, "condition", null) == null ? null : {
              title = vv.condition.title
              expression = templatestring(vv.condition.expression, {
                custom_roles = var.custom_roles
                organization = var.organization
                tag_names    = var.tag_names
                tag_root     = local.tag_root
              })
              description = lookup(vv.condition, "description", null)
            }
          }
        }
        iam_bindings_additive = {
          for kk, vv in v.folder_config.iam_bindings_additive :
          kk => {
            role   = vv.role
            member = contains(["ro", "rw"], vv.member) ? "${k}-${vv.member}" : vv.member
            condition = lookup(vv, "condition", null) == null ? null : {
              title = vv.condition.title
              expression = templatestring(vv.condition.expression, {
                custom_roles = var.custom_roles
                organization = var.organization
                tag_names    = var.tag_names
                tag_root     = local.tag_root
              })
              description = lookup(vv.condition, "description", null)
            }
          }
        }
        iam_by_principals = {
          for kk, vv in v.folder_config.iam_by_principals :
          (contains(["ro", "rw"], kk) ? "${k}-${kk}" : kk) => vv
        }
      })
      organization_config = merge(v.organization_config, {
        iam_bindings_additive = {
          for kk, vv in v.organization_config.iam_bindings_additive : kk => {
            member = contains(["ro", "rw"], vv.member) ? "${k}-${vv.member}" : vv.member
            role   = vv.role
            condition = lookup(vv, "condition", null) == null ? null : {
              title = vv.condition.title
              expression = templatestring(vv.condition.expression, {
                custom_roles = var.custom_roles
                organization = var.organization
                tag_names    = var.tag_names
                tag_root     = local.tag_root
              })
              description = lookup(vv.condition, "description", null)
            }
          }
        }
      })
    })
  }
  # environment folder permutations
  stage2_env_folders = flatten([
    for k, v in local.stage2 : [
      for ek, ev in var.environments : {
        key      = "${k}-${ek}"
        name     = ev.name
        stage    = k
        tag_name = ev.tag_name
      }
    ] if try(v.folder_config.create_env_folders, null) == true
  ])
  # stage 2 short names used to detect overlap in stage 3s
  stage2_shortnames = [for k, v in local.stage2 : v.short_name]
}

# top-level folder

module "stage2-folder" {
  source = "../../../modules/folder"
  for_each = {
    for k, v in local.stage2 : k => v if v.folder_config != null
  }
  parent = (
    each.value.folder_config.parent_id == null
    ? local.root_node
    : try(
      local.top_level_folder_ids[each.value.folder_config.parent_id],
      each.value.folder_config.parent_id
    )
  )
  name = each.value.folder_config.name
  iam = {
    for k, v in each.value.folder_config.iam :
    lookup(var.custom_roles, k, k) => [
      for m in v : lookup(local.principals_iam, m, m)
    ]
  }
  iam_bindings = {
    for k, v in each.value.folder_config.iam_bindings : k => merge(v, {
      members = [
        for m in v.members : lookup(local.principals_iam, m, m)
      ]
      role = lookup(var.custom_roles, v.role, v.role)
    })
  }
  iam_bindings_additive = {
    for k, v in each.value.folder_config.iam_bindings_additive : k => merge(v, {
      member = lookup(local.principals_iam, v.member, v.member)
      role   = lookup(var.custom_roles, v.role, v.role)
    })
  }
  iam_by_principals = {
    for k, v in each.value.folder_config.iam_by_principals :
    lookup(local.principals_iam, k, k) => [
      for r in v : lookup(var.custom_roles, r, r)
    ]
  }
  org_policies = each.value.folder_config.org_policies
  tag_bindings = merge({
    (var.tag_names.context) = local.tag_values["${var.tag_names.context}/${each.key}"].id
    }, {
    for k, v in each.value.folder_config.tag_bindings : k => try(
      local.tag_values[v].id, v
    )
  })
  depends_on = [module.top-level-folder]
}

# optional per-environment folders

module "stage2-folder-env" {
  source   = "../../../modules/folder"
  for_each = { for k in local.stage2_env_folders : k.key => k }
  parent   = module.stage2-folder[each.value.stage].id
  name     = each.value.name
  tag_bindings = {
    (var.tag_names.environment) = try(
      local.tag_values["${var.tag_names.environment}/${each.value.tag_name}"].id,
      null
    )
  }
}

# automation service accounts

module "stage2-sa-rw" {
  source     = "../../../modules/iam-service-account"
  for_each   = local.stage2
  project_id = var.automation.project_id
  name = templatestring(var.resource_names["sa-stage2_rw"], {
    name = each.value.short_name
  })
  display_name = (
    "Terraform resman ${each.key} service account."
  )
  prefix = "${var.prefix}-${local.environment_default.short_name}"
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.cicd-sa-rw[each.key].iam_email, null)
    ])
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectAdmin"]
  }
}

module "stage2-sa-ro" {
  source     = "../../../modules/iam-service-account"
  for_each   = local.stage2
  project_id = var.automation.project_id
  name = templatestring(var.resource_names["sa-stage2_ro"], {
    name = each.value.short_name
  })
  display_name = (
    "Terraform resman ${each.key} service account (read-only)."
  )
  prefix = "${var.prefix}-${local.environment_default.short_name}"
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.cicd-sa-ro[each.key].iam_email, null)
    ])
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = [var.custom_roles["storage_viewer"]]
  }
}

# automation bucket

module "stage2-bucket" {
  source     = "../../../modules/gcs"
  for_each   = local.stage2
  project_id = var.automation.project_id
  name = templatestring(var.resource_names["gcs-stage2"], {
    name = each.value.short_name
  })
  prefix     = "${var.prefix}-${local.environment_default.short_name}"
  location   = var.locations.gcs
  versioning = true
  iam = {
    "roles/storage.objectAdmin"  = [module.stage2-sa-rw[each.key].iam_email]
    "roles/storage.objectViewer" = [module.stage2-sa-ro[each.key].iam_email]
  }
}
