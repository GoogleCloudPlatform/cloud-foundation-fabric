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
  # project data from folders tree
  _folder_projects_raw = (
    {
      for f in try(fileset(local._folders_path, "**/*.yaml"), []) :
      trimsuffix(f, ".yaml") => merge(
        { parent = dirname(f) == "." ? "default" : dirname(f) },
        yamldecode(file("${local._folders_path}/${f}"))
      ) if !endswith(f, "/.config.yaml")
    }
  )
  # _projects_budgets = flatten([
  #   for k, v in local.projects_input : [
  #     for b in lookup(v, "billing_budgets", []) : {
  #       budget  = b
  #       project = lookup(v, "name", k)
  #     }
  #   ]
  # ])
  _projects_config = {
    data_defaults  = var.data_defaults
    data_overrides = var.data_overrides
  }
  _projects_input = {
    for k, v in merge(local._folder_projects_raw, local._projects_raw) :
    basename(k) => v
  }
  _projects_path = try(
    pathexpand(var.factories_config.projects_data_path), null
  )
  _projects_raw = {
    for f in try(fileset(local._projects_path, "**/*.yaml"), []) :
    trimsuffix(f, ".yaml") => yamldecode(file("${local._projects_path}/${f}"))
  }
  # projects_buckets = flatten([
  #   for k, v in local.projects_input : [
  #     for name, opts in lookup(v, "buckets", {}) : {
  #       project_key    = k
  #       project_name   = v.name
  #       name           = name
  #       description    = lookup(opts, "description", "Terraform-managed.")
  #       encryption_key = lookup(opts, "encryption_key", null)
  #       force_destroy = try(coalesce(
  #         var.data_overrides.bucket.force_destroy,
  #         try(opts.force_destroy, null),
  #         var.data_defaults.bucket.force_destroy,
  #       ), null)
  #       iam                   = lookup(opts, "iam", {})
  #       iam_bindings          = lookup(opts, "iam_bindings", {})
  #       iam_bindings_additive = lookup(opts, "iam_bindings_additive", {})
  #       labels                = lookup(opts, "labels", {})
  #       location              = lookup(opts, "location", null)
  #       prefix = coalesce(
  #         var.data_overrides.prefix,
  #         try(v.prefix, null),
  #         var.data_defaults.prefix
  #       )
  #       storage_class = lookup(
  #         opts, "storage_class", "STANDARD"
  #       )
  #       uniform_bucket_level_access = lookup(
  #         opts, "uniform_bucket_level_access", true
  #       )
  #       versioning = lookup(
  #         opts, "versioning", false
  #       )

  #     }
  #   ]
  # ])
  # projects_budgets = {
  #   for v in local._projects_budgets : v.budget => v.project...
  # }
  projects_input = merge(var.projects, local._projects_output)
  # projects_service_accounts = flatten([
  #   for k, project in local.projects_input : [
  #     for name, opts in project.service_accounts : {
  #       project_key = k
  #       name        = name
  #       display_name = coalesce(
  #         try(var.data_overrides.service_accounts.display_name, null),
  #         try(opts.display_name, null),
  #         try(var.data_defaults.service_accounts.display_name, null),
  #         "Terraform-managed."
  #       )
  #       iam                    = try(opts.iam, {})
  #       iam_billing_roles      = try(opts.iam_billing_roles, {})
  #       iam_organization_roles = try(opts.iam_organization_roles, {})
  #       iam_sa_roles           = try(opts.iam_sa_roles, {})
  #       iam_project_roles      = try(opts.iam_project_roles, {})
  #       iam_self_roles = distinct(concat(
  #         try(var.data_overrides.service_accounts.iam_self_roles, []),
  #         try(opts.iam_self_roles, []),
  #         try(var.data_defaults.service_accounts.iam_self_roles, []),
  #       ))
  #       iam_storage_roles = try(opts.iam_storage_roles, {})
  #       opts              = opts
  #     }
  #   ]
  # ])
}
