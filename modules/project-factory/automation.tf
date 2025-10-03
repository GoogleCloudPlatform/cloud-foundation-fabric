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
  _automation = merge(
    {
      for k, v in local.folders_input : k => {
        bucket           = try(v.automation.bucket, {})
        parent_name      = replace(k, "/", "-")
        parent_type      = "folder"
        prefix           = coalesce(try(v.automation.prefix, null), v.prefix)
        project          = try(v.automation.project, null)
        service_accounts = try(v.automation.service_accounts, {})
      } if try(v.automation.bucket, null) != null
    },
    {
      for k, v in local.projects_input : k => {
        bucket           = try(v.automation.bucket, {})
        parent_name      = k
        parent_type      = "project"
        prefix           = coalesce(try(v.automation.prefix, null), v.prefix)
        project          = try(v.automation.project, null)
        service_accounts = try(v.automation.service_accounts, {})
      } if try(v.automation.bucket, null) != null
    }
  )
  _automation_buckets = {
    for k, v in local._automation : k => merge(v.bucket, {
      automation_project = v.project
      parent_name        = v.parent_name
      name               = lookup(v.bucket, "name", "tf-state")
      create             = lookup(v.bucket, "create", true)
      prefix = try(coalesce(
        local.data_defaults.overrides.prefix,
        v.prefix,
        local.data_defaults.defaults.prefix
      ), null)
    })
  }
  _automation_sas = flatten(concat([
    for k, v in local._automation : [
      for sk, sv in v.service_accounts : merge(sv, {
        automation_project = v.project
        name               = sk
        parent             = k
        parent_name        = v.parent_name
      })
    ]
  ]))
  automation_buckets = {
    for k, v in local._automation_buckets :
    "${k}/automation/${v.name}" => v
  }
  automation_sas = {
    for k in local._automation_sas :
    "${k.parent}/automation/${k.name}" => k
  }
  automation_sas_iam_emails = {
    for k, v in local.automation_sas :
    "service_accounts/${v.parent}/automation/${v.name}" => module.automation-service-accounts[k].iam_email
  }
}

module "automation-bucket" {
  source     = "../gcs"
  for_each   = local.automation_buckets
  project_id = each.value.automation_project
  prefix = (
    each.value.create == false
    ? each.value.prefix
    : "${each.value.prefix}-${each.value.parent_name}"
  )
  name           = each.value.name
  bucket_create  = each.value.create
  encryption_key = lookup(each.value, "encryption_key", null)
  force_destroy = try(coalesce(
    local.data_defaults.overrides.bucket.force_destroy,
    each.value.force_destroy,
    local.data_defaults.defaults.force_destroy,
  ), null)
  context = merge(local.ctx, {
    project_ids    = local.ctx_project_ids
    iam_principals = local.ctx_iam_principals
  })
  iam                   = lookup(each.value, "iam", {})
  iam_bindings          = lookup(each.value, "iam_bindings", {})
  iam_bindings_additive = lookup(each.value, "iam_bindings_additive", {})
  labels                = lookup(each.value, "labels", {})
  managed_folders       = lookup(each.value, "managed_folders", {})
  location = each.value.create == false ? null : coalesce(
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
  source      = "../iam-service-account"
  for_each    = local.automation_sas
  project_id  = each.value.automation_project
  prefix      = each.value.parent_name
  name        = each.value.name
  description = lookup(each.value, "description", null)
  display_name = lookup(
    each.value,
    "display_name",
    "Service account ${each.value.name} for ${each.value.parent}."
  )
  context = merge(local.ctx, {
    project_ids = local.ctx_project_ids
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
  # iam_sa_roles           = lookup(each.value, "iam_sa_roles", {})
  # we don't interpolate buckets here as we can't use a dynamic key
  iam_storage_roles = lookup(each.value, "iam_storage_roles", {})
}

module "automation-service-accounts-iam" {
  source = "../iam-service-account"
  for_each = {
    for k, v in local.automation_sas :
    k => v if lookup(v, "iam_sa_roles", null) != null
  }
  project_id = (
    module.automation-service-accounts[each.key].service_account.project
  )
  name                   = module.automation-service-accounts[each.key].name
  service_account_create = false
  context = merge(local.ctx, {
    service_account_ids = local.project_sas_ids
  })
  iam_sa_roles = lookup(each.value, "iam_sa_roles", {})
}
