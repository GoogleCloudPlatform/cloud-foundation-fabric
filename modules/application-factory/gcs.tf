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
  prefix                        = try(each.value.prefix, null)
  location                      = try(each.value.location, null)
  storage_class                 = try(each.value.storage_class, "STANDARD")
  autoclass                     = try(each.value.autoclass, null)
  cors                          = try(each.value.cors, null)
  custom_placement_config       = try(each.value.custom_placement_config, null)
  default_event_based_hold      = try(each.value.default_event_based_hold, null)
  enable_hierarchical_namespace = try(each.value.enable_hierarchical_namespace, null)
  enable_object_retention       = try(each.value.enable_object_retention, null)
  encryption_key                = try(each.value.encryption_key, null)
  force_destroy                 = try(each.value.force_destroy, false)
  ip_filter                     = try(each.value.ip_filter, null)
  kms_autokeys                  = try(each.value.kms_autokeys, {})
  labels                        = try(each.value.labels, {})
  lifecycle_rules               = try(each.value.lifecycle_rules, {})
  logging_config                = try(each.value.logging_config, null)
  managed_folders               = try(each.value.managed_folders, {})
  notification_config           = try(each.value.notification_config, null)
  objects_to_upload             = try(each.value.objects_to_upload, {})
  public_access_prevention      = try(each.value.public_access_prevention, null)
  requester_pays                = try(each.value.requester_pays, null)
  retention_policy              = try(each.value.retention_policy, null)
  rpo                           = try(each.value.rpo, null)
  soft_delete_retention         = try(each.value.soft_delete_retention, null)
  uniform_bucket_level_access   = try(each.value.uniform_bucket_level_access, true)
  versioning                    = try(each.value.versioning, null)
  website                       = try(each.value.website, null)
  tag_bindings                  = try(each.value.tag_bindings, {})
  context                       = local.ctx_phase_2
  iam                           = try(each.value.iam, {})
  iam_bindings                  = try(each.value.iam_bindings, {})
  iam_bindings_additive         = try(each.value.iam_bindings_additive, {})
  iam_by_principals             = try(each.value.iam_by_principals, {})
}
