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

locals {
  projects = { for k, v in local._network_projects : k => merge(
    {
      billing_account        = try(v.project_config.billing_account, var.billing_account.id)
      prefix                 = try(v.project_config.prefix, var.prefix)
      parent                 = try(v.project_config.parent, var.folder_ids.networking)
      shared_vpc_host_config = try(v.project_config.shared_vpc_host_config, null)
      iam = merge(try(v.project_config.iam, {}), {
        (var.custom_roles.project_iam_viewer) = try(local.iam_viewer_principals["dev"], [])
      })
      iam_bindings = merge(try(v.project_config.iam_bindings, {}), (
        lookup(local.iam_delegated_principals, "dev", null) == null ? {} : {
          sa_delegated_grants = {
            role    = "roles/resourcemanager.projectIamAdmin"
            members = try(local.iam_delegated_principals["dev"], [])
            condition = {
              title       = "dev_stage3_sa_delegated_grants"
              description = "${var.environments["dev"].name} host project delegated grants."
              expression = format(
                "api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly([%s])",
                local.iam_delegated
              )
            }
          }
        }
      ))
    },
    v.project_config)
  }
}

module "projects" {
  source                 = "../../../modules/project"
  for_each               = local.projects
  billing_account        = each.value.billing_account
  name                   = each.value.name
  parent                 = each.value.parent
  prefix                 = each.value.prefix
  services               = each.value.services
  shared_vpc_host_config = each.value.shared_vpc_host_config
  iam                    = each.value.iam
  iam_bindings           = each.value.iam_bindings
  #TODO(sruffilli): implement metric_scopes and tag_bindings
  tag_bindings = local.has_env_folders ? {} : {
    environment = local.env_tag_values["dev"]
  }
}
