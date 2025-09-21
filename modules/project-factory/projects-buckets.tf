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
  projects_buckets = flatten([
    for k, v in local.projects_input : [
      for name, opts in lookup(v, "buckets", {}) : {
        project_key    = k
        project_name   = v.name
        name           = name
        create         = lookup(opts, "create", true)
        description    = lookup(opts, "description", "Terraform-managed.")
        encryption_key = lookup(opts, "encryption_key", null)
        force_destroy = try(coalesce(
          local.data_defaults.overrides.bucket.force_destroy,
          try(opts.force_destroy, null),
          local.data_defaults.defaults.bucket.force_destroy,
        ), null)
        iam                   = lookup(opts, "iam", {})
        iam_bindings          = lookup(opts, "iam_bindings", {})
        iam_bindings_additive = lookup(opts, "iam_bindings_additive", {})
        iam_by_principals     = lookup(opts, "iam_by_principals", {})
        labels                = lookup(opts, "labels", {})
        location              = lookup(opts, "location", null)
        managed_folders       = lookup(opts, "managed_folders", {})
        prefix = coalesce(
          local.data_defaults.overrides.prefix,
          try(v.prefix, null),
          local.data_defaults.defaults.prefix
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
}

module "buckets" {
  source = "../gcs"
  for_each = {
    for k in local.projects_buckets : "${k.project_key}/${k.name}" => k
  }
  project_id     = module.projects[each.value.project_key].project_id
  prefix         = each.value.prefix
  name           = "${each.value.project_name}-${each.value.name}"
  bucket_create  = each.value.create
  encryption_key = each.value.encryption_key
  force_destroy  = each.value.force_destroy
  context = merge(local.ctx, {
    project_ids = local.ctx_project_ids
    iam_principals = merge(
      local.ctx.iam_principals,
      local.projects_sas_iam_emails,
      local.automation_sas_iam_emails
    )
  })
  iam                   = each.value.iam
  iam_bindings          = each.value.iam_bindings
  iam_bindings_additive = each.value.iam_bindings_additive
  iam_by_principals     = each.value.iam_by_principals
  labels                = each.value.labels
  location = coalesce(
    local.data_defaults.overrides.storage_location,
    lookup(each.value, "location", null),
    local.data_defaults.defaults.storage_location
  )
  managed_folders             = each.value.managed_folders
  storage_class               = each.value.storage_class
  uniform_bucket_level_access = each.value.uniform_bucket_level_access
  versioning                  = each.value.versioning
}
