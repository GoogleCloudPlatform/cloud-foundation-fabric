/**
 * Copyright 2024 Google LLC
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

# tfdoc:file:description Automation projects locals and resources.

locals {
  automation_buckets = flatten([
    for k, v in local.projects : [
      for ks, kv in try(v.automation.buckets, {}) : merge(kv, {
        automation_project = v.automation.project
        name               = ks
        prefix             = v.prefix
        project            = k
      })
    ]
  ])
  automation_sa = flatten([
    for k, v in local.projects : [
      for ks, kv in try(v.automation.service_accounts, {}) : merge(kv, {
        automation_project = v.automation.project
        name               = ks
        prefix             = v.prefix
        project            = k
      })
    ]
  ])
}

module "automation-buckets" {
  source = "../gcs"
  for_each = {
    for k in local.automation_buckets : "${k.project}/${k.name}" => k
  }
  project_id     = each.value.automation_project
  prefix         = each.value.prefix
  name           = "${each.value.project}-${each.value.name}"
  encryption_key = lookup(each.value, "encryption_key", null)
  iam = {
    for k, v in lookup(each.value, "iam", {}) : k => [
      for vv in v : try(
        module.automation-service-accounts["${each.value.project}/${vv}"].iam_email,
        var.factories_config.context.iam_principals[vv],
        vv
      )
    ]
  }
  iam_bindings = {
    for k, v in lookup(each.value, "iam_bindings", {}) : k => merge(v, {
      members = [
        for vv in v.members : try(
          module.automation-service-accounts["${each.value.project}/${vv}"].iam_email,
          var.factories_config.context.iam_principals[vv],
          vv
        )
      ]
    })
  }
  iam_bindings_additive = {
    for k, v in lookup(each.value, "iam_bindings_additive", {}) : k => merge(v, {
      member = try(
        module.automation-service-accounts["${each.value.project}/${v.member}"].iam_email,
        var.factories_config.context.iam_principals[v.member],
        v.member
      )
    })
  }
  labels                      = lookup(each.value, "labels", {})
  location                    = lookup(each.value, "location", "EU")
  storage_class               = lookup(each.value, "storage_class", "STANDARD")
  uniform_bucket_level_access = lookup(each.value, "uniform_bucket_level_access", true)
  versioning                  = lookup(each.value, "versioning", false)
}

module "automation-service-accounts" {
  source = "../iam-service-account"
  for_each = {
    for k in local.automation_sa : "${k.project}/${k.name}" => k
  }
  project_id  = each.value.automation_project
  prefix      = each.value.prefix
  name        = "${each.value.project}-${each.value.name}"
  description = lookup(each.value, "description", null)
  display_name = lookup(
    each.value,
    "display_name",
    "Service account ${each.value.name} for ${each.value.project}."
  )
  iam = {
    for k, v in lookup(each.value, "iam", {}) : k => [
      for vv in v : lookup(
        var.factories_config.context.iam_principals, vv, vv
      )
    ]
  }
  iam_bindings = {
    for k, v in lookup(each.value, "iam_bindings", {}) : k => merge(v, {
      members = [
        for vv in v.members : lookup(
          var.factories_config.context.iam_principals, vv, vv
        )
      ]
    })
  }
  iam_bindings_additive = {
    for k, v in lookup(each.value, "iam_bindings_additive", {}) : k => merge(v, {
      member = lookup(
        var.factories_config.context.iam_principals, v.member, v.member
      )
    })
  }
  iam_billing_roles      = lookup(each.value, "iam_billing_roles", {})
  iam_folder_roles       = lookup(each.value, "iam_folder_roles", {})
  iam_organization_roles = lookup(each.value, "iam_organization_roles", {})
  iam_project_roles      = lookup(each.value, "iam_project_roles", {})
  iam_sa_roles           = lookup(each.value, "iam_sa_roles", {})
  # we don't interpolate buckets here as we can't use a dynamic key
  iam_storage_roles = lookup(each.value, "iam_storage_roles", {})
}
