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

# tfdoc:file:description Phase 2: GCS buckets.

locals {
  _gcs_raw = {
    for f in try(fileset(local.paths.gcs, "*.yaml"), []) :
    trimsuffix(f, ".yaml") => yamldecode(
      file("${local.paths.gcs}/${f}")
    )
  }
}

module "gcs" {
  source                        = "../gcs"
  for_each                      = local._gcs_raw
  project_id                    = try(each.value.project_id, null)
  name                          = try(each.value.name, each.key)
  location                      = try(each.value.location, null)
  storage_class                 = try(each.value.storage_class, "STANDARD")
  prefix                        = try(each.value.prefix, null)
  autoclass                     = try(each.value.autoclass, null)
  cors                          = try(each.value.cors, null)
  default_event_based_hold      = try(each.value.default_event_based_hold, null)
  enable_hierarchical_namespace = try(each.value.enable_hierarchical_namespace, null)
  enable_object_retention       = try(each.value.enable_object_retention, null)
  encryption_key                = try(each.value.encryption_key, null)
  force_destroy                 = try(each.value.force_destroy, false)
  labels                        = try(each.value.labels, {})
  lifecycle_rules               = try(each.value.lifecycle_rules, {})
  logging_config                = try(each.value.logging_config, null)
  public_access_prevention      = try(each.value.public_access_prevention, null)
  requester_pays                = try(each.value.requester_pays, null)
  retention_policy              = try(each.value.retention_policy, null)
  soft_delete_retention         = try(each.value.soft_delete_retention, null)
  uniform_bucket_level_access   = try(each.value.uniform_bucket_level_access, true)
  versioning                    = try(each.value.versioning, null)
  website                       = try(each.value.website, null)
  tag_bindings                  = try(each.value.tag_bindings, {})
  context = merge(local.ctx, {
    iam_principals  = local.ctx_iam_principals
    storage_buckets = local.ctx_storage_buckets
  })
  iam                   = try(each.value.iam, {})
  iam_bindings          = try(each.value.iam_bindings, {})
  iam_bindings_additive = try(each.value.iam_bindings_additive, {})
  iam_by_principals     = try(each.value.iam_by_principals, {})
}
