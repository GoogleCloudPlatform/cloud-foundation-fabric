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

# tfdoc:file:description Projects and billing budgets factory resources.

locals {
  _iam_role_sets_path = try(local.paths.iam_role_sets, null)
  _iam_role_sets_raw = (
    local._iam_role_sets_path == null
    ? {}
    : {
      for f in try(fileset(local._iam_role_sets_path, "*.yaml"), []) :
      replace(f, ".yaml", "") => yamldecode(
        file("${local._iam_role_sets_path}/${f}")
      )
    }
  )
  _iam_role_sets = {
    for k, v in local._iam_role_sets_raw :
    coalesce(try(v.name, null), k) => lookup(v, "roles", [])
  }
  ctx = merge(var.context, {
    iam_role_sets = merge(try(var.context.iam_role_sets, {}), local._iam_role_sets)
  })
  ctx_iam_principals = merge(
    local.ctx.iam_principals,
    local.iam_principals
  )
  iam_principals = merge(
    local.projects_sas_iam_emails,
    local.automation_sas_iam_emails
  )
  paths = {
    for k, v in var.factories_config.paths : k => try(pathexpand(
      var.factories_config.basepath == null || startswith(v, "/") || startswith(v, ".")
      ? v :
      "${var.factories_config.basepath}/${v}"
    ), null)
  }
}

resource "terraform_data" "defaults_preconditions" {
  lifecycle {
    precondition {
      condition = (
        var.data_defaults.locations.storage != null ||
        var.data_overrides.locations.storage != null
      )
      error_message = "No default storage location defined in defaults or overrides variables."
    }
    # precondition {
    #   condition     = local.paths == null
    #   error_message = jsonencode(local.paths)
    # }
  }
}
