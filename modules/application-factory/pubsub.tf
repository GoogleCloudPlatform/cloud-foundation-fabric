/**
 * Copyright 2026 Google LLC
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

# tfdoc:file:description Phase 2: Pub/Sub topics.

locals {
  _pubsub_raw = {
    for f in try(fileset(local.paths.pubsub, "*.yaml"), []) :
    trimsuffix(f, ".yaml") => yamldecode(
      file("${local.paths.pubsub}/${f}")
    )
  }
}

module "pubsub" {
  source   = "../pubsub"
  for_each = local._pubsub_raw
  project_id                         = try(each.value.project_id, null)
  name                               = try(each.value.name, each.key)
  kms_key                            = try(each.value.kms_key, null)
  labels                             = try(each.value.labels, {})
  message_retention_duration         = try(each.value.message_retention_duration, null)
  message_storage_enforce_in_transit = try(each.value.message_storage_enforce_in_transit, null)
  regions                            = try(each.value.regions, [])
  schema                             = try(each.value.schema, null)
  subscriptions                      = try(each.value.subscriptions, {})
  context = merge(local.ctx, {
    iam_principals = local.ctx_iam_principals
  })
}
