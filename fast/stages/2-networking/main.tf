/**
 * Copyright 2022 Google LLC
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
  # Governed by var.factories_config - transforms factory config paths to absolute paths
  paths = {
    for k, v in var.factories_config : k => try(pathexpand(v), null)
  }

  # Governed by var.factories_config.defaults (default: "data/defaults.yaml") + defaults.yaml filename
  _defaults = yamldecode(file(local.paths.defaults))
  _iam_principals = merge(
    var.iam_principals,
    {
      for k, v in var.service_accounts :
      # k => "serviceAccount:${v}" if v != null
      k => "serviceAccount:${v}" if v != null
    },
    try(var.context.iam_principals, {})
  )
  _computed_iam_principals = merge(
    { for k, v in local._iam_principals : "service_accounts/${k}" => v if startswith(v, "serviceAccount:") },
    { for k, v in local._iam_principals : k => v if !startswith(v, "serviceAccount:") }
  )

  ctx = {
    custom_roles = merge(
      var.custom_roles, var.context.custom_roles
    )
    folder_ids = merge(
      var.folder_ids, var.context.folder_ids
    )
    iam_principals = local._computed_iam_principals
    locations = merge(
      var.locations, var.context.locations
    )
    project_ids = merge(
      var.project_ids, var.context.project_ids
    )
    tag_values = merge(
      var.tag_values, var.context.tag_values
    )
    # Additional networking-specific context can be added here
    # vpc_host_projects, vpc_sc_perimeters, etc.
  }

  defaults = local._defaults
  # Governed by local._defaults.global.billing_account
  # billing_account = try(local._defaults.global.billing_account, null)
  # # Governed by local._defaults.global.locations with hardcoded defaults
  # locations = try(local._defaults.global.locations, {})
  # # Governed by local._defaults.global.organization.id existence check
  # organization = (
  #   try(local._defaults.global.organization.id, null) == null
  #   ? null
  #   : local._defaults.global.organization
  # )

  vpcs_defaults = {
    defaults  = try(local._defaults.vpcs.defaults, {})
    overrides = try(local._defaults.vpcs.overrides, {})
  }

  # Governed by local._defaults.output_files.* (from defaults.yaml output_files section)
  output_files = {
    local_path     = try(local._defaults.output_files.local_path, null)     # From defaults.yaml
    storage_bucket = try(local._defaults.output_files.storage_bucket, null) # From defaults.yaml
  }
}