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

locals {
  _policy_tags_path = try(pathexpand(var.factories_config.policy_tags), null)
  _policy_tags_data = {
    for f in try(fileset(local._policy_tags_path, "*.yaml"), []) :
    trimsuffix(f, ".yaml") => yamldecode(file("${local._policy_tags_path}/${f}"))
  }
  _context = merge(local.context, {
    project_ids = merge(
      local.context.project_ids,
      module.project-factory.project_ids
    )
  })
}

module "aspect-types" {
  source     = "../../../modules/dataplex-aspect-types"
  project_id = local._defaults.resources.aspect_types.project_id
  location = try(
    local._defaults.resources.aspect_types.location,
    "$locations:primary"
  )
  context = local._context
  factories_config = {
    aspect_types = var.factories_config.aspect_types
  }
}

module "policy-tags" {
  source   = "../../../modules/data-catalog-policy-tag"
  for_each = local._policy_tags_data
  project_id = local._defaults.resources.policy_tags.project_id
  name       = each.key
  location = try(
    local._defaults.resources.policy_tags.location,
    "$locations:primary"
  )
  tags    = each.value.tags
  context = local._context
}
