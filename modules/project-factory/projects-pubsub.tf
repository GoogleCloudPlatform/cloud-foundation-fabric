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
  projects_pubsub_topics = flatten([
    for k, v in local.projects_input : [
      for name, opts in lookup(v, "pubsub_topics", {}) : {
        project_key                = k
        name                       = name
        iam                        = lookup(opts, "iam", {})
        iam_bindings               = lookup(opts, "iam_bindings", {})
        iam_bindings_additive      = lookup(opts, "iam_bindings_additive", {})
        iam_by_principals          = lookup(opts, "iam_by_principals", {})
        kms_key                    = lookup(opts, "kms_key", null)
        labels                     = lookup(opts, "labels", {})
        message_retention_duration = lookup(opts, "message_retention_duration", null)
        regions                    = lookup(opts, "regions", [])
        schema                     = lookup(opts, "schema", null)
        subscriptions              = lookup(opts, "subscriptions", {})
      }
    ]
  ])
}

module "pubsub" {
  source = "../pubsub"
  for_each = {
    for k in local.projects_pubsub_topics : "${k.project_key}/${k.name}" => k
  }
  project_id = module.projects-iam[each.value.project_key].project_id
  name       = each.value.name
  context = merge(local.ctx, {
    iam_principals = merge(
      local.ctx.iam_principals,
      local.projects_sas_iam_emails,
      local.automation_sas_iam_emails,
      lookup(local.self_sas_iam_emails, each.value.project_key, {})
    )
    kms_keys    = merge(local.ctx.kms_keys, local.kms_keys, local.kms_autokeys)
    locations   = local.ctx.locations
    project_ids = local.ctx_project_ids
  })
  iam                        = each.value.iam
  iam_bindings               = each.value.iam_bindings
  iam_bindings_additive      = each.value.iam_bindings_additive
  iam_by_principals          = each.value.iam_by_principals
  kms_key                    = each.value.kms_key
  labels                     = each.value.labels
  message_retention_duration = each.value.message_retention_duration
  regions                    = each.value.regions
  schema                     = each.value.schema
  subscriptions              = each.value.subscriptions
}
