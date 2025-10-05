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
  of_buckets = {
    for k, v in module.factory.storage_buckets :
    "$storage_buckets:${k}" => v
  }
  of_outputs_bucket = (
    local.output_files.storage_bucket == null
    ? null
    : lookup(
      local.of_buckets,
      local.output_files.storage_bucket,
      local.output_files.storage_bucket
    )
  )
  of_service_accounts = {
    for k, v in module.factory.service_account_emails :
    "$iam_principals:service_accounts/${k}" => v
  }
  of_path = (
    local.output_files.local_path == null
    ? null
    : pathexpand(local.output_files.local_path)
  )
  of_template = file("assets/providers.tf.tpl")
  of_tfvars = {
    globals = {
      billing_account = {
        id = local.defaults.billing_account
      }
      groups    = local.ctx.iam_principals
      locations = local.defaults.locations
      organization = {
        customer_id = try(local.defaults.organization.customer_id, null)
        domain      = local.organization.domain
        id          = local.organization_id
      }
      prefix = local.defaults.prefix
      universe = try(
        local.project_defaults.overrides.universe,
        local.project_defaults.defaults.universe,
        null
      )
    }
    org-setup = {
      automation = {
        outputs_bucket = local.of_outputs_bucket
      }
      custom_roles = module.organization[0].custom_role_id
      folder_ids = merge(
        local.ctx.folder_ids,
        module.factory.folder_ids
      )
      iam_principals = local.iam_principals
      logging = {
        writer_identities = module.organization-iam.0.sink_writer_identities
      }
      project_ids = merge(
        local.ctx.project_ids,
        module.factory.project_ids
      )
      project_numbers = module.factory.project_numbers
      # project_numbers = module.factory.project_numbers
      service_accounts = module.factory.service_account_emails
      storage_buckets  = module.factory.storage_buckets
      tag_values = merge(
        local.ctx.project_ids,
        local.org_tag_values
      )
    }
  }
  of_universe_domain = try(
    local.project_defaults.overrides.universe.domain,
    local.project_defaults.defaults.universe.domain,
    null
  )
}

resource "local_file" "providers" {
  for_each        = local.of_path == null ? {} : local.output_files.providers
  file_permission = "0644"
  filename        = "${local.of_path}/providers/${each.key}-providers.tf"
  content = templatestring(local.of_template, {
    bucket = lookup(
      local.of_buckets, each.value.bucket, each.value.bucket
    )
    prefix = lookup(each.value, "prefix", null)
    service_account = lookup(
      local.of_service_accounts, each.value.service_account, each.value.service_account
    )
    universe_domain = local.of_universe_domain
  })
}

resource "google_storage_bucket_object" "providers" {
  for_each = local.output_files.storage_bucket == null ? {} : local.output_files.providers
  bucket   = local.of_outputs_bucket
  name     = "providers/${each.key}-providers.tf"
  content = templatestring(local.of_template, {
    bucket = lookup(
      local.of_buckets, each.value.bucket, each.value.bucket
    )
    prefix = lookup(each.value, "prefix", null)
    service_account = lookup(
      local.of_service_accounts, each.value.service_account, each.value.service_account
    )
    universe_domain = local.of_universe_domain
  })
}

resource "local_file" "tfvars" {
  for_each        = toset(local.of_path == null ? [] : keys(local.of_tfvars))
  file_permission = "0644"
  filename        = "${local.of_path}/tfvars/0-${each.key}.auto.tfvars.json"
  content         = jsonencode(local.of_tfvars[each.key])
}

resource "google_storage_bucket_object" "tfvars" {
  for_each = toset(local.output_files.storage_bucket == null ? [] : keys(local.of_tfvars))
  bucket   = local.of_outputs_bucket
  name     = "tfvars/0-${each.key}.auto.tfvars.json"
  content  = jsonencode(local.of_tfvars[each.key])
}
