# Copyright 2024 Google LLC
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

# tfdoc:file:description Core resources.

locals {
  shared_vpc_project = try(var.vpc_config.host_project, null)
  subnet = (
    local.use_shared_vpc
    ? var.vpc_config.subnet_self_link
    : values(module.vpc[0].subnet_self_links)[0]
  )
  use_shared_vpc = var.vpc_config != null
  vpc = (
    local.use_shared_vpc
    ? var.vpc_config.network_self_link
    : module.vpc[0].self_link
  )
}

module "project" {
  source          = "../../../modules/project"
  name            = var.project_id
  parent          = try(var.project_create.parent, null)
  billing_account = try(var.project_create.billing_account_id, null)
  project_create  = var.project_create != null
  prefix          = var.project_create == null ? null : var.prefix
  services = [
    "aiplatform.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerystorage.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "compute.googleapis.com",
    "ml.googleapis.com",
    "notebooks.googleapis.com",
    "servicenetworking.googleapis.com",
    "stackdriver.googleapis.com",
    "storage.googleapis.com",
    "storage-component.googleapis.com"
  ]
  shared_vpc_service_config = local.shared_vpc_project == null ? null : {
    attach       = true
    host_project = local.shared_vpc_project
  }
  service_encryption_key_ids = {
    "aiplatform.googleapis.com" = compact([var.service_encryption_keys.compute])
    "compute.googleapis.com"    = compact([var.service_encryption_keys.compute])
    "bigquery.googleapis.com"   = compact([var.service_encryption_keys.bq])
    "storage.googleapis.com"    = compact([var.service_encryption_keys.storage])
  }
  service_config = {
    disable_on_destroy = false, disable_dependent_services = false
  }
}
