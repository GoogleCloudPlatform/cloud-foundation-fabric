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

module "factory" {
  source = "../../../modules/project-factory"
  context = {
    custom_roles = merge(
      var.custom_roles, var.context.custom_roles
    )
    folder_ids = merge(
      var.folder_ids, var.context.folder_ids
    )
    iam_principals = merge(
      var.iam_principals,
      {
        for k, v in var.service_accounts :
        k => "serviceAccount:${v}" if v != null
      },
      var.context.iam_principals
    )
    kms_keys = merge(
      var.kms_keys, var.context.kms_keys
    )
    locations = merge(
      var.locations, var.context.locations
    )
    notification_channels = var.context.notification_channels
    project_ids = merge(
      var.project_ids, var.host_project_ids, var.context.project_ids
    )
    tag_values = merge(
      var.tag_values, var.context.tag_values
    )
    vpc_sc_perimeters = merge(
      var.perimeters, var.context.vpc_sc_perimeters
    )
  }
  data_defaults = {
    # more defaults are available, check the project factory variables
    billing_account  = var.billing_account.id
    storage_location = var.locations.storage
  }
  data_merges = {
    services = [
      "logging.googleapis.com",
      "monitoring.googleapis.com"
    ]
  }
  data_overrides = {
    prefix = var.prefix
  }
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
