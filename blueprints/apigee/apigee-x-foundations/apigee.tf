/**
 * Copyright 2023 Google LLC
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
  control_plan_in_eu_or_us = (
    try(contains(["europe", "us"],
    split("-", var.apigee_config.organization.api_consumer_data_location)[0]), false)
  )
  organization = merge(var.apigee_config.organization,
    {
      authorized_network = (var.apigee_config.organization.disable_vpc_peering
        ? null :
        try(module.apigee_vpc[0].id, module.shared_vpc[0].id)
      )
      database_encryption_key = try(
        module.database_kms[0].key_ids["database-key"],
      var.apigee_config.organization.database_encryption_key_config.id)
      api_consumer_data_encryption_key = try(
        module.api_consumer_data_kms[0].key_ids["api-consumer-data-key"],
      var.apigee_config.organization.api_consumer_data_encryption_key_config.id)
      control_plane_encryption_key = try(
        module.control_plane_kms[0].key_ids["control-plane-key"],
      var.apigee_config.organization.control_plane_encryption_key_config.id)
      runtime_type = "CLOUD"
    }
  )
  instances = { for k, v in var.apigee_config.instances : k => merge(v, {
    disk_encryption_key = try(
      module.disks_kms[k].key_ids["disk-key"],
      v.disk_encryption_key_config.id,
      null
    )
  }) }
}

module "apigee" {
  source               = "../../../modules/apigee"
  project_id           = module.project.project_id
  organization         = local.organization
  envgroups            = var.apigee_config.envgroups
  environments         = var.apigee_config.environments
  instances            = local.instances
  endpoint_attachments = var.apigee_config.endpoint_attachments
  addons_config        = var.apigee_config.addons_config
}
