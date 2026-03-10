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

# tfdoc:file:description Phase 2: Artifact Registry.

locals {
  _artifact_registry_raw = {
    for f in try(fileset(local.paths.artifact_registry, "*.yaml"), []) :
    trimsuffix(f, ".yaml") => yamldecode(
      file("${local.paths.artifact_registry}/${f}")
    )
  }
}

module "artifact-registry" {
  source   = "../artifact-registry"
  for_each = local._artifact_registry_raw
  project_id = lookup(
    local.ctx.project_ids, try(each.value.project_id, ""), try(each.value.project_id, null)
  )
  name = try(each.value.name, each.key)
  location = lookup(
    local.ctx.locations, try(each.value.location, ""), try(each.value.location, null)
  )
  description                   = try(each.value.description, "Terraform-managed registry")
  format                        = each.value.format
  labels                        = try(each.value.labels, {})
  encryption_key                = try(each.value.encryption_key, null)
  cleanup_policies              = try(each.value.cleanup_policies, null)
  cleanup_policy_dry_run        = try(each.value.cleanup_policy_dry_run, null)
  enable_vulnerability_scanning = try(each.value.enable_vulnerability_scanning, null)
  tag_bindings                  = try(each.value.tag_bindings, {})
  iam                   = try(each.value.iam, {})
  iam_bindings          = try(each.value.iam_bindings, {})
  iam_bindings_additive = try(each.value.iam_bindings_additive, {})
  iam_by_principals     = try(each.value.iam_by_principals, {})
}
