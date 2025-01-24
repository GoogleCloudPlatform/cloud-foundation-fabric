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
  _stage2 = {
    for f in local._stage2_files :
    split(".", f)[0] => yamldecode(file(
      "${coalesce(local._stage2_path, "-")}/${f}"
    ))
  }
  # merge stage 3 from factory and variable data
  stage2 = merge(
    # normalize factory data attributes with defaults and nulls
    {
      for k, v in local._stage2 : k => {
        short_name = coalesce(lookup(v, "short_name", null), k)
        cicd_config = lookup(v, "cicd_config", null) == null ? null : {
          identity_provider = v.cicd_config.identity_provider
          repository = merge(v.cicd_config.repository, {
            branch = try(v.cicd_config.repository.branch, null)
            type   = try(v.cicd_config.repository.type, "github")
          })
        }
        folder_config = lookup(v, "folder_config", null) == null ? null : {
          name                  = v.folder_config.name
          iam                   = try(v.folder_config.iam, {})
          iam_bindings          = try(v.folder_config.iam_bindings, {})
          iam_bindings_additive = try(v.folder_config.iam_bindings_additive, {})
          iam_by_principals     = try(v.folder_config.iam_by_principals, {})
          org_policies          = try(v.folder_config.org_policies, {})
          parent_id             = try(v.folder_config.parent_id, null)
        }
        organization_config = {
          iam                   = try(v.organization_config.iam, {})
          iam_bindings          = try(v.organization_config.iam_bindings, {})
          iam_bindings_additive = try(v.organization_config.iam_bindings_additive, {})
          iam_by_principals     = try(v.organization_config.iam_by_principals, {})
        }
        _iam_sa_names = { ro = "${k}-r", rw = k }
      }
    },
    var.fast_stage_2
  )

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
      for m in v : lookup(
        local.principals_iam, lookup(each.value._iam_sa_names, m, m), m
      )
    ]
  }
  iam_bindings = {
    for k, v in each.value.folder_config.iam_bindings : k => merge(v, {
      members = [
        for m in v.members : lookup(
          local.principals_iam, lookup(each.value._iam_sa_names, m, m), m
        )
      ]
      role = lookup(var.custom_roles, v.role, v.role)
    })
  }
  iam_bindings_additive = {
    for k, v in each.value.folder_config.iam_bindings_additive : k => merge(v, {
      member = lookup(
        local.principals_iam, lookup(
          each.value._iam_sa_names, v.member, v.member
        ), v.member
      )
      role = lookup(var.custom_roles, v.role, v.role)
    })
  }
  iam_by_principals = {
    for k, v in each.value.folder_config.iam_by_principals :
    lookup(local.principals, k, k) => [
      for r in v : lookup(var.custom_roles, r, r)
    ]
  }
  tag_bindings = {
    k = local.tag_values["context/${k}"].id
  }
  depends_on = [module.top-level-folder]
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
      try(module.cicd-sa-rw["${each.key}-prod"].iam_email, null)
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
      try(module.cicd-sa-ro["${each.key}-prod"].iam_email, null)
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
