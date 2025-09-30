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
    bucket     = try(local.defaults.output_files.storage_bucket, null)
    local_path = try(local.defaults.output_files.local_path, null)
    pattern = {
      bucket = try(
        local.defaults.output_files.provider_pattern.storage_bucket, null
      )
      sa_ro = try(
        local.defaults.output_files.provider_pattern.service_accounts.ro, null
      )
      sa_rw = try(
        local.defaults.output_files.provider_pattern.service_accounts.rw, null
      )
    }
    providers = try(local.defaults.output_files.providers, {})
  }
  _of_pattern_use = local._of.pattern.bucket != null && (
    local._of.pattern.sa_ro != null || local._of.pattern.sa_rw != null
  )
  # compute projects dereferencing service accounts for provider template
  _of_providers_projects = !local._of_pattern_use ? {} : {
    for k, v in module.factory.projects : k => {
      ro = local._of.pattern.sa_ro == null ? null : lookup(
        module.factory.service_account_emails,
        "${k}/${local._of.pattern.sa_ro}",
        null
      )
      rw = local._of.pattern.sa_rw == null ? null : lookup(
        module.factory.service_account_emails,
        "${k}/${local._of.pattern.sa_rw}",
        null
      )
    }
  }
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
    # templated providers, read-only service account
    local._of.pattern.sa_ro == null ? {} : {
      for k, v in local._of_providers_projects : "${k}-ro" => {
        filename        = "${k}-ro"
        prefix          = k
        service_account = v.ro
        storage_bucket  = local._of.pattern.bucket
      } if v.ro != null
    },
    # templated providers, read-write service account
    local._of.pattern.sa_rw == null ? {} : {
      for k, v in local._of_providers_projects : "${k}-rw" => {
        filename        = "${k}-rw"
        prefix          = k
        service_account = v.rw
        storage_bucket  = local._of.pattern.bucket
      } if v.rw != null
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
  # list of service accounts for dereferencing single providers
  of_service_accounts = {
    for k, v in module.factory.service_account_emails :
    "$iam_principals:service_accounts/${k}" => v
  }
  # dereference output files bucket
  of_storage_bucket = local._of.bucket == null ? null : lookup(
    local.of_storage_buckets, local._of.bucket, local._of.bucket
  )
  # list of storage buckets for dereferencing output files bucket
  of_storage_buckets = {
    for k, v in module.factory.storage_buckets : "$storage_buckets:${k}" => v
  }
  # TODO: allow customizing template path from defaults file
  of_template = file("assets/providers.tf.tpl")
  # tfvars files are generated for each project that has a providers file
  of_tfvars_projects = distinct([
    for k, v in local._of_providers_projects :
    k if v.ro != null || v.rw != null
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
