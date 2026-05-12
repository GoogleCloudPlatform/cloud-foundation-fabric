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

# tfdoc:file:description Taxonomy resources.

module "taxonomies" {
  source = "../data-catalog-policy-tag"
  for_each = {
    for k, v in local.projects_input : k => v
    if try(v.factories_config.data_catalog_taxonomy, null) != null
  }
  project_id = module.projects[each.key].project_id
  factories_config = {
    taxonomy = lookup(each.value.factories_config, "data_catalog_taxonomy", null) == null ? null : try(pathexpand(
      var.factories_config.basepath == null || startswith(each.value.factories_config.data_catalog_taxonomy, "/") || startswith(each.value.factories_config.data_catalog_taxonomy, ".")
      ? each.value.factories_config.data_catalog_taxonomy :
      "${var.factories_config.basepath}/${each.value.factories_config.data_catalog_taxonomy}"
    ), null)
  }
  name     = "taxonomy"
  location = try(each.value.locations.storage, "europe-west1")
  context = merge(local.ctx, {
    iam_principals = merge(
      local.ctx_iam_principals,
      lookup(local.self_sas_iam_emails, each.key, {}),
      local.projects_service_agents
    )
    project_ids = merge(
      local.ctx.project_ids,
      { for k, v in module.projects : k => v.project_id }
    )
  })
}
