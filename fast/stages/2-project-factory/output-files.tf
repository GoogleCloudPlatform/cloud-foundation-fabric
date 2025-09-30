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

/*
foo      = {
  + "iac-0/iac-shared-outputs"                        = "tf-playground-iac-0-iac-shared-outputs"
  + "iac-0/iac-shared-state"                          = "tf-playground-iac-0-iac-shared-state"
  + "prod-os-apt-0/automation/iac-0-iac-shared-state" = "tf-playground-iac-0-iac-shared-state"
}
*/

locals {
  # output files configurations
  _of = {
    local_path       = try(local.defaults.output_files.local_path, null)
    provider_pattern = try(local.defaults.output_files.provider_pattern, {})
    providers        = try(local.defaults.output_files.providers, {})
    storage_bucket   = try(local.defaults.output_files.storage_bucket, null)
  }
  # initial templated provider definitions for each project
  _of_providers_templated = flatten([
    for k, v in module.factory.projects : [
      for s in lookup(local._of.provider_pattern, "service_accounts", []) : {
        project         = k
        service_account = "${k}/${s}"
        storage_bucket = lookup(
          local._of.provider_pattern, "storage_bucket", null
        )
      }
    ]
  ])
  # merge single and templated providers dereferencing service accounts
  _of_providers = merge(
    # single providers
    {
      for k, v in local._of.providers : k => merge(v, {
        filename = k
        prefix   = k
        # single providers can reference external service accounts
        service_account = lookup(
          local.of_service_accounts, v.service_account, v.service_account
        )
      })
    },
    # templated providers
    {
      for v in local._of_providers_templated : v.service_account => merge(v, {
        filename = "${v.project}-${reverse(split("/", v.service_account))[0]}"
        prefix   = v.project
        # templated providers can only reference internal service accounts
        service_account = try(
          module.factory.service_account_emails["${v.service_account}"],
          null
        )
      })
    }
  )
  of_path = (
    local._of.local_path == null ? null : pathexpand(local._of.local_path)
  )
  of_prefix = try(local.defaults.output_files.prefix, "projects")
  # filter provider definitions based on bucket and service account existence
  of_providers = {
    for k, v in local._of_providers : k => v
    if v.storage_bucket != null && v.service_account != null
  }
  # dereference service accounts for single providers
  of_service_accounts = {
    for k, v in module.factory.service_account_emails :
    "$iam_principals:service_accounts/${k}" => v
  }
  # dereference output files bucket
  of_storage_bucket = local._of.storage_bucket == null ? null : lookup(
    local.of_storage_buckets, local._of.storage_bucket, local._of.storage_bucket
  )
  of_storage_buckets = {
    for k, v in module.factory.storage_buckets :
    "$storage_buckets:${k}" => v
  }
  of_template = file("assets/providers.tf.tpl")
  # tfvars files are generated for each project that has a providers file
  of_tfvars_projects = distinct([
    for k, v in local.of_providers :
    v.project if lookup(v, "project", null) != null
  ])
}

resource "local_file" "providers" {
  for_each        = local.of_path == null ? {} : local.of_providers
  file_permission = "0644"
  filename = (
    "${local.of_path}/providers/${local.of_prefix}/${each.value.filename}.tf"
  )
  content = templatestring(local.of_template, {
    bucket = lookup(
      local.of_storage_buckets,
      each.value.storage_bucket,
      each.value.storage_bucket
    )
    prefix          = each.value.prefix
    service_account = each.value.service_account
  })
}

resource "local_file" "tfvars" {
  for_each = toset(
    local.of_path == null ? [] : local.of_tfvars_projects
  )
  file_permission = "0644"
  filename = (
    "${local.of_path}/tfvars/${local.of_prefix}/${each.value}.auto.tfvars.json"
  )
  content = jsonencode(module.factory.projects[each.value])
}

resource "google_storage_bucket_object" "providers" {
  for_each = local.of_storage_bucket == null ? {} : local.of_providers
  bucket   = local.of_storage_bucket
  name     = "providers/${local.of_prefix}/${each.value.filename}.tf"
  content = templatestring(local.of_template, {
    bucket = lookup(
      local.of_storage_buckets,
      each.value.storage_bucket,
      each.value.storage_bucket
    )
    prefix          = each.value.prefix
    service_account = each.value.service_account
  })
}

resource "google_storage_bucket_object" "tfvars" {
  for_each = toset(
    local.of_storage_bucket == null ? [] : local.of_tfvars_projects
  )
  bucket  = local.of_storage_bucket
  name    = "tfvars/${local.of_prefix}/${each.value}.auto.tfvars.json"
  content = jsonencode(module.factory.projects[each.value])
}
