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

# tfdoc:file:description Dedicated project factory.
locals {

  _projects_input = { for k, v in local.network_projects : k => v.project_config }
  _projects_config = {
    data_defaults = {
      billing_account = var.billing_account
      prefix          = var.prefix
      parent          = var.parent_id
      project_reuse   = var.project_reuse
    }
  }
  projects = local._projects_output
}

module "projects" {
  source                     = "../project"
  for_each                   = local.projects
  billing_account            = each.value.billing_account
  name                       = each.value.name
  parent                     = each.value.parent
  prefix                     = each.value.prefix
  services                   = each.value.services
  shared_vpc_host_config     = each.value.shared_vpc_host_config
  iam                        = each.value.iam
  iam_bindings               = each.value.iam_bindings
  iam_bindings_additive      = each.value.iam_bindings_additive
  iam_by_principals          = each.value.iam_by_principals
  iam_by_principals_additive = each.value.iam_by_principals_additive
  org_policies               = each.value.org_policies
  project_reuse              = each.value.project_reuse
  quotas                     = each.value.quotas
}
