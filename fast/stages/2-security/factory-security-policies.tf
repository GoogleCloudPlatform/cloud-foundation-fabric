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

# tfdoc:file:description Security policies factory.

locals {
  _security_policies_files = local.paths.security_policies == null ? [] : fileset(
    local.paths.security_policies, "**/*.yaml"
  )
  _security_policies_data = {
    for f in local._security_policies_files : replace(f, ".yaml", "") => yamldecode(
      file("${local.paths.security_policies}/${f}")
    )
  }
  security_policies = {
    for k, v in local._security_policies_data : try(v.name, k) => v
  }
}

module "security-policies" {
  source                  = "../../../modules/net-cloud-armor"
  for_each                = local.security_policies
  name                    = each.key
  parent_id               = each.value.parent_id
  attachments             = try(each.value.attachments, {})
  advanced_options_config = try(each.value.advanced_options_config, null)
  default_rule_config     = null
  rules                   = try(each.value.rules, {})
  context = {
    cidr_ranges      = local.ctx.cidr_ranges
    cidr_ranges_sets = local.ctx.cidr_ranges_sets
    folder_ids       = local.ctx_folders
    project_ids      = local.ctx_projects.project_ids
    project_numbers  = local.ctx_projects.project_numbers
  }
}
