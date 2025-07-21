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
  automation_buckets = {
    for k, v in local.projects_input :
    k => merge(try(v.automation.bucket, {}), {
      automation_project = v.automation.project
      prefix = coalesce(
        try(v.automation.prefix, null),
        "${v.prefix}-${v.name}"
      )
      project_name = v.name
    }) if try(v.automation.bucket, null) != null
  }
  automation_sa = flatten([
    for k, v in local.projects_input : [
      for ks, kv in try(v.automation.service_accounts, {}) : merge(kv, {
        automation_project = v.automation.project
        name               = ks
        prefix = coalesce(
          try(v.automation.prefix, null),
          "${v.prefix}-${v.name}"
        )
        project      = k
        project_name = v.name
      })
    ]
  ])
  automation_sas_iam_emails = {
    for k, v in module.automation-service-accounts : "automation/service_accounts/${k}" => v.iam_email
  }
}

module "automation-bucket" {
  source   = "../gcs"
  for_each = local.automation_buckets
  # we cannot use interpolation here as we would get a cycle
  # from the IAM dependency in the outputs of the main project
  project_id     = each.value.automation_project
  prefix         = each.value.prefix
  name           = "tf-state"
  encryption_key = lookup(each.value, "encryption_key", null)
  force_destroy = try(coalesce(
    local.data_defaults.overrides.bucket.force_destroy,
    each.value.force_destroy,
    local.data_defaults.defaults.force_destroy,
  ), null)
  context = merge(local.ctx, {
    project_ids = merge(local.ctx.project_ids, local.project_ids)
    iam_principals = merge(
      local.ctx.iam_principals,
      local.projects_sas_iam_emails
    )
  })
  iam                   = lookup(each.value, "iam", {})
  iam_bindings          = lookup(each.value, "iam_bindings", {})
  iam_bindings_additive = lookup(each.value, "iam_bindings_additive", {})
  labels                = lookup(each.value, "labels", {})
  location = coalesce(
    local.data_defaults.overrides.storage_location,
    lookup(each.value, "location", null),
    local.data_defaults.defaults.storage_location
  )
  storage_class = lookup(
    each.value, "storage_class", "STANDARD"
  )
  uniform_bucket_level_access = lookup(
    each.value, "uniform_bucket_level_access", true
  )
  versioning = lookup(
    each.value, "versioning", false
  )
}

module "automation-service-accounts" {
  source = "../iam-service-account"
  for_each = {
    for k in local.automation_sa : "${k.project}/automation/${k.name}" => k
  }
  # we cannot use interpolation here as we would get a cycle
  # from the IAM dependency in the outputs of the main project
  project_id  = each.value.automation_project
  prefix      = each.value.prefix
  name        = each.value.name
  description = lookup(each.value, "description", null)
  display_name = lookup(
    each.value,
    "display_name",
    "Service account ${each.value.name} for ${each.value.project}."
  )
  context = merge(local.ctx, {
    project_ids = merge(local.ctx.project_ids, local.project_ids)
    iam_principals = merge(
      local.ctx.iam_principals,
      local.projects_sas_iam_emails
    )
  })
  iam                    = lookup(each.value, "iam", {})
  iam_bindings           = lookup(each.value, "iam_bindings", {})
  iam_bindings_additive  = lookup(each.value, "iam_bindings_additive", {})
  iam_billing_roles      = lookup(each.value, "iam_billing_roles", {})
  iam_folder_roles       = lookup(each.value, "iam_folder_roles", {})
  iam_organization_roles = lookup(each.value, "iam_organization_roles", {})
  iam_project_roles      = lookup(each.value, "iam_project_roles", {})
  iam_sa_roles           = lookup(each.value, "iam_sa_roles", {})
  # we don't interpolate buckets here as we can't use a dynamic key
  iam_storage_roles = lookup(each.value, "iam_storage_roles", {})
}
