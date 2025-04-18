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

# tfdoc:file:description Projects factory locals.

locals {
  _hierarchy_projects_full_path = (
    {
      for f in try(fileset(local._folders_path, "**/*.yaml"), []) :
      trimsuffix(f, ".yaml") => merge(
        { parent = dirname(f) == "." ? "default" : dirname(f) },
        yamldecode(file("${local._folders_path}/${f}"))
      ) if !endswith(f, "/_config.yaml")
    }
  )
  _project_path = try(pathexpand(var.factories_config.projects_data_path), null)
  _projects_full_path = {
    for f in try(fileset(local._project_path, "**/*.yaml"), []) :
    trimsuffix(f, ".yaml") => yamldecode(file("${local._project_path}/${f}"))
  }
  _projects_input = merge(
    local._hierarchy_projects_full_path,
    local._projects_full_path
  )
  _project_budgets = flatten([
    for k, v in local._projects_input : [
      for b in try(v.billing_budgets, []) : {
        budget  = b
        project = lookup(v, "name", k)
      }
    ]
  ])
  _projects_config = {
    data_overrides = var.data_overrides
    data_defaults  = var.data_defaults
  }
  projects = {
    for k, v in local._projects_output : k => merge({
      buckets          = try(v.buckets, {})
      service_accounts = try(v.service_accounts, {})
    }, v)
  }
  project_budgets = {
    for v in local._project_budgets : v.budget => v.project...
  }
  buckets = flatten([
    for k, v in local.projects : [
      for name, opts in v.buckets : {
        project_key           = k
        project_name          = v.name
        name                  = name
        description           = lookup(opts, "description", "Terraform-managed.")
        encryption_key        = lookup(opts, "encryption_key", null)
        iam                   = lookup(opts, "iam", {})
        iam_bindings          = lookup(opts, "iam_bindings", {})
        iam_bindings_additive = lookup(opts, "iam_bindings_additive", {})
        labels                = lookup(opts, "labels", {})
        location              = lookup(opts, "location", null)
        prefix = coalesce(
          var.data_overrides.prefix,
          try(v.prefix, null),
          var.data_defaults.prefix
        )
        storage_class = lookup(
          opts, "storage_class", "STANDARD"
        )
        uniform_bucket_level_access = lookup(
          opts, "uniform_bucket_level_access", true
        )
        versioning = lookup(
          opts, "versioning", false
        )

      }
    ]
  ])
  service_accounts = flatten([
    for k, project in local.projects : [
      for name, opts in project.service_accounts : {
        project_key = k
        name        = name
        display_name = coalesce(
          try(var.data_overrides.service_accounts.display_name, null),
          try(opts.display_name, null),
          try(var.data_defaults.service_accounts.display_name, null),
          "Terraform-managed."
        )
        iam                    = try(opts.iam, {})
        iam_billing_roles      = try(opts.iam_billing_roles, {})
        iam_organization_roles = try(opts.iam_organization_roles, {})
        iam_sa_roles           = try(opts.iam_sa_roles, {})
        iam_project_roles      = try(opts.iam_project_roles, {})
        iam_self_roles = distinct(concat(
          try(var.data_overrides.service_accounts.iam_self_roles, []),
          try(opts.iam_self_roles, []),
          try(var.data_defaults.service_accounts.iam_self_roles, []),
        ))
        iam_storage_roles = try(opts.iam_storage_roles, {})
        opts              = opts
      }
    ]
  ])
}
