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
  ob_project = {
    project_id = try(
      replace(local.defaults.observability.project_id, "$project_ids:", ""), null
    )
    number = try(
      replace(local.defaults.observability.number, "$project_numbers:", ""), null
    )
  }
}

module "projects-observability" {
  source = "../../../modules/project"
  count = (
    local.ob_project.project_id != null && local.ob_project.number != null ? 1 : 0
  )
  name = lookup(
    module.factory.project_ids,
    local.ob_project.project_id,
    local.ob_project.project_id
  )
  project_reuse = {
    use_data_source = false
    attributes = {
      name = lookup(
        module.factory.project_ids,
        local.ob_project.project_id,
        local.ob_project.project_id
      )
      number = lookup(
        module.factory.project_numbers,
        local.ob_project.number,
        local.ob_project.number
      )
    }
  }
  context = merge(local.ctx, {
    folder_ids  = module.factory.folder_ids
    kms_keys    = module.factory.kms_keys
    log_buckets = module.factory.log_buckets
    project_ids = module.factory.project_ids
  })
  factories_config = {
    observability = var.factories_config.observability
  }
}


