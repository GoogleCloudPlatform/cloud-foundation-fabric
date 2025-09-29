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
  _of = {
    local_path       = try(local.defaults.output_files.local_path, null)
    provider_pattern = try(local.defaults.output_files.provider_pattern, {})
    providers        = try(local.defaults.output_files.providers, {})
    storage_bucket   = try(local.defaults.output_files.storage_bucket, null)
    tfvars_pattern   = try(local.defaults.output_files.tfvars_pattern, {})
  }
  # templated provider definitions for each project
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
    {
      for k, v in local._of.providers : k => merge(v, {
        filename = k
        project  = k
        service_account = try(
          module.factory.service_account_emails["${k}/${v.service_account}"],
          null
        )
      })
    },
    {
      for v in local._of_providers_templated : v.service_account => merge(v, {
        filename = "${v.project}-${reverse(split("/", v.service_account))[0]}"
        service_account = try(
          module.factory.service_account_emails["${v.service_account}"],
          null
        )
      })
    }
  )
  # templated tfvars definitions for each project
  _of_tfvars = local._of.tfvars_pattern == null ? {} : {
    for k, v in module.factory.projects : k => lookup(
      local._of.tfvars_pattern, "storage_bucket", null
    )
  }
  of_path = (
    local._of.local_path == null ? null : pathexpand(local._of.local_path)
  )
  of_prefix = try(local.defaults.output_files.prefix, "projects")
  # filter provider definitions based on bucket and service account existence
  of_providers = {
    for k, v in local._of_providers : k => v
    if v.storage_bucket != null && v.service_account != null
  }
  of_storage_bucket = local._of.storage_bucket == null ? null : lookup(
    local.of_storage_buckets, local._of.storage_bucket, local._of.storage_bucket
  )
  of_storage_buckets = {
    for k, v in module.factory.storage_buckets : "$storage_buckets:${k}" => v
  }
  of_template = file("assets/providers.tf.tpl")
  of_tfvars   = { for k, v in local._of_tfvars : k => v if v != null }
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
    prefix          = each.value.project
    service_account = each.value.service_account
  })
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
    prefix          = each.value.project
    service_account = each.value.service_account
  })
}
