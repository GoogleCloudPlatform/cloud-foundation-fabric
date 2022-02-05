# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# tfdoc:file:description Core locals.

locals {
  _networks = {
    load = {
      #TODO Fix Network name logic
      network_name = element(split("/", var.network_config.network != null ? var.network_config.network : module.lod-vpc[0].self_link), length(split("/", var.network_config.network != null ? var.network_config.network : module.lod-vpc[0].self_link)) - 1)
      network      = var.network_config.network != null ? var.network_config.network : module.lod-vpc[0].self_link
      subnet       = var.network_config.network != null ? var.network_config.vpc_subnet_self_link.load : module.lod-vpc[0].subnet_self_links["${var.composer_config.region}/${local.prefix_lod}-subnet"]
      subnet_range = var.network_config.vpc_subnet_range.load
    }
    orchestration = {
      #TODO Fix Network name logic
      network_name = element(split("/", var.network_config.network != null ? var.network_config.network : module.orc-vpc[0].self_link), length(split("/", var.network_config.network != null ? var.network_config.network : module.orc-vpc[0].self_link)) - 1)
      network      = var.network_config.network != null ? var.network_config.network : module.orc-vpc[0].self_link
      subnet       = var.network_config.network != null ? var.network_config.vpc_subnet_self_link.orchestration : module.orc-vpc[0].subnet_self_links["${var.composer_config.region}/${local.prefix_orc}-subnet"]
      subnet_range = var.network_config.vpc_subnet_range.orchestration
    }
    transformation = {
      #TODO Fix Network name logic
      network_name = element(split("/", var.network_config.network != null ? var.network_config.network : module.trf-vpc[0].self_link), length(split("/", var.network_config.network != null ? var.network_config.network : module.trf-vpc[0].self_link)) - 1)
      network      = var.network_config.network != null ? var.network_config.network : module.trf-vpc[0].self_link
      subnet       = var.network_config.network != null ? var.network_config.vpc_subnet_self_link.transformation : module.trf-vpc[0].subnet_self_links["${var.composer_config.region}/${local.prefix_trf}-subnet"]
      subnet_range = var.network_config.vpc_subnet_range.transformation
    }
  }

  _shared_vpc_service_config = var.network_config.network != null ? {
    attach       = true
    host_project = var.network_config.host_project
  } : null

  groups                  = { for k, v in var.groups : k => "${v}@${var.organization.domain}" }
  groups_iam              = { for k, v in local.groups : k => "group:${v}" }
  service_encryption_keys = var.service_encryption_keys

  # Uncomment this section and assigne comment the previous line

  # service_encryption_keys = {
  #   bq       = module.sec-kms-1.key_ids.bq
  #   composer = module.sec-kms-2.key_ids.composer
  #   dataflow = module.sec-kms-2.key_ids.dataflow
  #   storage  = module.sec-kms-1.key_ids.storage
  #   pubsub   = module.sec-kms-0.key_ids.pubsub
  # }
}
