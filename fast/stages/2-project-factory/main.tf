/**
 * Copyright 2022 Google LLC
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

# tfdoc:file:description Project factory.

locals {
  _context = {
    for k, v in var.context : k => merge(v, try(local.defaults.context[k], {}))
  }
  context = merge(local._context, {
    vpc_sc_perimeters = merge(var.perimeters, local._context.vpc_sc_perimeters)
  })
  defaults = yamldecode(file(pathexpand(var.factories_config.defaults)))
  fast_defaults = {
    billing_account = coalesce(
      var.data_defaults.billing_account,
      var.billing_account.id
    )
    prefix = coalesce(
      var.data_defaults.prefix, var.prefix
    )
  }
  project_defaults = {
    defaults = {
      for k, v in var.data_defaults : k => try(
        local.defaults.projects.defaults[k],
        lookup(local.fast_defaults, k, v)
      )
    }
    merges = {
      for k, v in var.data_merges : k => try(
        local.defaults.projects.merges[k], v
      )
    }
    overrides = merge(
      {
        for k, v in var.data_overrides : k => try(
          local.defaults.projects.overrides[k], v
        )
      },
      {
        universe = var.universe
      }
    )
  }
  subnet_self_links = flatten([
    for net, subnets in var.subnet_self_links : [
      for subnet_name, subnet_link in subnets : {
        key  = "${net}/${subnet_name}"
        link = subnet_link
      }
    ]
  ])
}

module "factory" {
  source = "../../../modules/project-factory"
  context = {
    condition_vars = merge({
      subnet_self_links = {
        for v in local.subnet_self_links : v.key => v.link
      }
    }, local.context.condition_vars)
    custom_roles = merge(var.custom_roles, local.context.custom_roles)
    folder_ids   = merge(var.folder_ids, local.context.folder_ids)
    iam_principals = merge(
      var.iam_principals,
      {
        for k, v in var.service_accounts :
        k => "serviceAccount:${v}" if v != null
      },
      local.context.iam_principals
    )
    kms_keys              = merge(var.kms_keys, local.context.kms_keys)
    locations             = local.context.locations
    notification_channels = local.context.notification_channels
    project_ids = merge(
      var.project_ids, var.host_project_ids, var.security_project_ids, local.context.project_ids
    )
    tag_values        = merge(var.tag_values, local.context.tag_values)
    vpc_sc_perimeters = merge(var.perimeters, local.context.vpc_sc_perimeters)
  }
  data_defaults  = local.project_defaults.defaults
  data_merges    = local.project_defaults.merges
  data_overrides = local.project_defaults.overrides
  factories_config = merge(var.factories_config, {
    budgets = {
      billing_account_id = try(
        var.factories_config.budgets.billing_account_id, var.billing_account.id
      )
      data = try(
        var.factories_config.budgets.data, "data/budgets"
      )
    }
  })
}
