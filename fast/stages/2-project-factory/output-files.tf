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
  # output files configurations
  _of_p = try(local.defaults.output_files.providers_pattern, {})
  _of = {
    bucket           = try(local.defaults.output_files.storage_bucket, null)
    local_path       = try(local.defaults.output_files.local_path, null)
    p_bucket         = try(local._of_p.storage_bucket, null)
    p_folders_create = try(local._of_p.folders.create, true)
    p_iam_assign     = try(local._of_p.folders.iam_assign, true)
    p_ro             = try(local._of_p.service_accounts_match.ro, null)
    p_rw             = try(local._of_p.service_accounts_match.rw, null)
    providers        = try(local.defaults.output_files.providers, {})
    template = try(
      local._of_p.providers_template_path, "assets/providers.tf.tpl"
    )
  }
  _of_p_use = local._of.p_bucket != null && (
    local._of.p_ro != null || local._of.p_rw != null
  )
  # pattern projects with service account dereferencing
  _of_p_projects = !local._of_p_use ? {} : {
    for k, v in module.factory.projects : k => {
      ro = local._of.p_ro == null ? null : lookup(
        module.factory.service_account_emails, "${k}/${local._of.p_ro}", null
      )
      rw = local._of.p_rw == null ? null : lookup(
        module.factory.service_account_emails, "${k}/${local._of.p_rw}", null
      )
    }
  }
  # merge single and templated providers dereferencing service accounts
  _of_providers = merge(
    # single providers
    {
      for k, v in local._of.providers : k => {
        filename = k
        prefix   = lookup(v, "set_prefix", true) == true ? k : null
        # single providers can reference external service accounts
        service_account = lookup(
          local.of_service_accounts, v.service_account, v.service_account
        )
        storage_bucket = lookup(v, "storage_bucket", null)
      }
    },
    # templated providers, read-only service account
    local._of.p_ro == null ? {} : {
      for k, v in local._of_p_projects : "${k}-ro" => {
        filename        = "${k}-ro"
        prefix          = k
        service_account = v.ro
        storage_bucket  = local._of.p_bucket
      } if v.ro != null
    },
    # templated providers, read-write service account
    local._of.p_rw == null ? {} : {
      for k, v in local._of_p_projects : "${k}-rw" => {
        filename        = "${k}-rw"
        prefix          = k
        service_account = v.rw
        storage_bucket  = local._of.p_bucket
      } if v.rw != null
    }
  )
  of_path = (
    local._of.local_path == null ? null : pathexpand(local._of.local_path)
  )
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
  # template file for providers
  of_template = file(local._of.template)
  # tfvars files are generated for each project that has a providers file
  of_tfvars_projects = distinct([
    for k, v in local._of_p_projects : k if v.ro != null || v.rw != null
  ])
}

resource "local_file" "providers" {
  for_each        = local.of_path == null ? {} : local.of_providers
  file_permission = "0644"
  filename = (
    "${local.of_path}/providers/${each.value.filename}.tf"
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
    "${local.of_path}/tfvars/${each.value}.auto.tfvars.json"
  )
  content = jsonencode(module.factory.projects[each.value])
}

resource "google_storage_bucket_object" "providers" {
  for_each = local.of_storage_bucket == null ? {} : local.of_providers
  bucket   = local.of_storage_bucket
  name     = "providers/${each.value.filename}.tf"
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
  name    = "tfvars/${each.value}.auto.tfvars.json"
  content = jsonencode(module.factory.projects[each.value])
}
