/**
 * Copyright 2024 Google LLC
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

# tfdoc:file:TODO.
locals {
  #TODO(sruffilli): yaml file name should be == project name, unless overridden explicitly by a "name" attribute in project_config.
  _network_projects = {
    for f in local._network_factory_files :
    split(".", f)[0] => yamldecode(file(
      "${coalesce(local._network_factory_path, "-")}/${f}"
    ))
  }

  projects = { for k, v in local._network_projects : k => merge(
    {
      billing_account            = try(v.project_config.billing_account, var.billing_account)
      prefix                     = try(v.project_config.prefix, var.prefix)
      parent                     = try(v.project_config.parent, var.parent_id)
      shared_vpc_host_config     = try(v.project_config.shared_vpc_host_config, null)
      iam                        = try(v.project_config.iam, {})
      iam_bindings               = try(v.project_config.iam_bindings, {})
      iam_bindings_additive      = try(v.project_config.iam_bindings_additive, {})
      iam_by_principals          = try(v.project_config.iam_by_principals, {})
      iam_by_principals_additive = try(v.project_config.iam_by_principals_additive, {})
      services                   = try(v.project_config.services, [])
      org_policies               = try(v.project_config.org_policies, {})
    },
    v.project_config)
  }
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
  #TODO(sruffilli): implement metric_scopes and tag_bindings
  #TODO: check
  # tag_bindings = local.has_env_folders ? {} : {
  #   environment = local.env_tag_values["dev"]
  # }
}
