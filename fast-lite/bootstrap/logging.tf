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
  _log_sinks_folders = flatten([
    for k, v in module.factory.data.folders : [
      for lk, lv in try(v.logging.sinks, {}) : {
        key    = "folders/${k}/${lk}"
        name   = lk
        parent = module.factory.folders[k]
        sink   = lv
      }
    ]
  ])
  log_sinks = merge(
    local.organization_id == null ? {} : {
      for k, v in try(local.organization.logging.sinks, {}) :
      "organization/${k}" => {
        destination = merge({ type = "logging" }, v.destination)
        filter      = v.filter
        name        = k
        parent      = module.organization[0].id
      }
    },
    {
      for v in local._log_sinks_folders : v.key => {
        destination = merge({ type = "logging" }, v.sink.destination)
        filter      = v.sink.filter
        name        = v.name
        parent      = v.parent
      }
    }
  )
  logging_ctx = {
    custom_roles = merge(
      local.ctx.custom_roles, module.organization[0].custom_role_id
    )
    iam_principals = merge(
      local.ctx.iam_principals, module.factory.iam_principals
    )
    locations = merge(local.ctx.locations, {
      "default/logging" = local.defaults.locations.logging
      "default/storage" = local.defaults.locations.storage
    })
    project_ids = merge(
      local.ctx.project_ids, module.factory.project_ids
    )
  }
}
