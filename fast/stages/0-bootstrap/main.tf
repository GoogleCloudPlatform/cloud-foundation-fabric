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
  paths = {
    for k, v in var.factories_config : k => try(pathexpand(v), null)
  }
  # fail if we have no valid defaults
  _defaults = yamldecode(file(local.paths.defaults))
  ctx = merge(var.context, {
    iam_principals = local.iam_principals
    locations = {
      for k, v in local.defaults.locations :
      k => v if k != "pubsub"
    }
  })
  defaults = {
    billing_account = try(local._defaults.global.billing_account, null)
    locations = merge(try(local._defaults.global.locations, {}), {
      bigquery = "eu"
      logging  = "global"
      pubsub   = []
      storage  = "eu"
    })
    organization = (
      try(local._defaults.global.organization.id, null) == null
      ? null
      : local._defaults.global.organization
    )
    prefix = try(
      local.project_defaults.defaults.prefix,
      local.project_defaults.overrides.prefix,
      null
    )
  }
  iam_principals = merge(
    local.org_iam_principals,
    var.context.iam_principals,
    try(local._defaults.context.iam_principals, {})
  )
  output_files = {
    local_path     = try(local._defaults.output_files.local_path, null)
    storage_bucket = try(local._defaults.output_files.storage_bucket, null)
    providers      = try(local._defaults.output_files.providers, {})
  }
  project_defaults = {
    defaults  = try(local._defaults.projects.defaults, {})
    overrides = try(local._defaults.projects.overrides, {})
  }
}

# TODO: streamine location replacements

resource "terraform_data" "precondition" {
  lifecycle {
    precondition {
      condition     = try(local.defaults.billing_account, null) != null
      error_message = "No billing account set in global defaults."
    }
    precondition {
      condition = (
        local.organization_id != null ||
        try(local.project_defaults.defaults.parent, null) != null ||
        try(local.project_defaults.overrides.parent, null) != null
      )
      error_message = "Project parent must be set in project defaults or overrides if no organization id is set."
    }
    precondition {
      condition = (
        try(local.project_defaults.defaults.prefix, null) != null ||
        try(local.project_defaults.overrides.prefix, null) != null
      )
      error_message = "Prefix must be set in project defaults or overrides."
    }
    precondition {
      condition = (
        try(local.project_defaults.defaults.storage_location, null) != null ||
        try(local.project_defaults.overrides.storage_location, null) != null
      )
      error_message = "Storage location must be set in project defaults or overrides."
    }
  }
}
