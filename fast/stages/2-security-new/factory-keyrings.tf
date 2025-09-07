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
  _keyrings_path = try(
    pathexpand(var.factories_config.keyrings), null
  )
  _keyrings_files = try(
    fileset(local._keyrings_path, "**/*.yaml"),
    []
  )
  _keyrings = {
    for f in local._keyrings_files : trimsuffix(basename(f), ".yaml") => yamldecode(file(
      "${coalesce(local._keyrings_path, "-")}/${f}"
    ))
  }
  keyrings = {
    for k, v in local._keyrings : k => {
      location              = v.location
      project_id            = v.project_id
      name                  = lookup(v, "name", k)
      reuse                 = lookup(v, "reuse", false)
      iam                   = lookup(v, "iam", {})
      iam_bindings          = lookup(v, "iam_bindings", {})
      iam_bindings_additive = lookup(v, "iam_bindings_additive", {})
      tag_bindings          = lookup(v, "tag_bindings", {})
      keys = {
        for kk, kv in lookup(v, "keys", {}) : kk => {
          id                    = lookup(kv, "name", null)
          iam                   = lookup(kv, "iam", {})
          iam_bindings          = lookup(kv, "iam_bindings", {})
          iam_bindings_additive = lookup(kv, "iam_bindings_additive", {})
          destroy_scheduled_duration = lookup(
            kv, "destroy_scheduled_duration", null
          )
          rotation_period = lookup(kv, "rotation_period", null)
          labels          = lookup(kv, "labels", null)
          purpose         = lookup(kv, "purpose", null)
          skip_initial_version_creation = lookup(
            kv, "skip_initial_version_creation", null
          )
          version_template = lookup(kv, "version_template", null)
        }
      }
    } if lookup(v, "project_id", null) != null
  }
}

module "kms" {
  source     = "../../../modules/kms"
  for_each   = local.keyrings
  project_id = each.value.project_id
  keyring = {
    location = each.value.location
    name     = each.value.name
  }
  iam                   = each.value.iam
  iam_bindings          = each.value.iam_bindings
  iam_bindings_additive = each.value.iam_bindings_additive
  keyring_create        = !each.value.reuse
  keys                  = each.value.keys
  tag_bindings          = each.value.tag_bindings
  context = merge(local.ctx, {
    project_ids = merge(local.ctx.project_ids, module.factory.project_ids)
  })
  depends_on = [module.factory]
}
output "foo" { value = module.factory.project_ids }
