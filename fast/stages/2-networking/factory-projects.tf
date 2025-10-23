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

# tfdoc:file:description Projects factory.

locals {
  ctx_folders = merge(local.ctx.folder_ids, module.projects.folder_ids, {
    organization = "organizations/${var.organization.id}"
  })
  ctx_projects = {
    project_ids = merge(local.ctx.project_ids, module.projects.project_ids)
  }
  project_defaults = {
    defaults = merge(
      {
        billing_account = var.billing_account.id
        prefix          = var.prefix
      },
      lookup(var.folder_ids, local.defaults.folder_name, null) == null ? {} : {
        parent = lookup(var.folder_ids, local.defaults.folder_name, null)
      },
      try(local._defaults.projects.defaults, {})
    )
    overrides = try(local._defaults.projects.overrides, {})
  }
}

moved {
  from = module.factory
  to   = module.projects
}

module "projects" {
  source         = "../../../modules/project-factory"
  data_defaults  = local.project_defaults.defaults
  data_overrides = local.project_defaults.overrides
  context        = local.ctx
  factories_config = {
    folders  = var.factories_config.folders
    projects = var.factories_config.projects
  }
}
