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

# tfdoc:file:description Load project and VPC.

locals {
  group_iam_lod = {
    "${local.groups.data-engineers}" = [
      "roles/compute.viewer",
      "roles/dataflow.admin",
      "roles/dataflow.developer",
      "roles/viewer",
    ]
  }
  iam_lod = {
    "roles/bigquery.jobUser" = [
      module.lod-sa-df-0.iam_email
    ]
    "roles/compute.serviceAgent" = [
      "serviceAccount:${module.lod-prj.service_accounts.robots.compute}"
    ]
    "roles/dataflow.admin" = [
      module.orc-sa-cmp-0.iam_email,
      module.lod-sa-df-0.iam_email
    ]
    "roles/dataflow.worker" = [
      module.lod-sa-df-0.iam_email
    ]
    "roles/dataflow.serviceAgent" = [
      "serviceAccount:${module.lod-prj.service_accounts.robots.dataflow}"
    ]
    "roles/storage.objectAdmin" = [
      "serviceAccount:${module.lod-prj.service_accounts.robots.dataflow}",
      module.lod-sa-df-0.iam_email
    ]
  }
  prefix_lod = "${var.prefix}-lod"
}

# Project

module "lod-prj" {
  source          = "../../../modules/project"
  name            = try(var.project_ids["load"], "lod")
  parent          = try(var.project_create.parent, null)
  billing_account = try(var.project_create.billing_account_id, null)
  project_create  = can(var.project_ids["load"])
  prefix          = can(var.project_ids["load"]) ? var.prefix : null
  # additive IAM bindings avoid disrupting bindings in existing project
  iam          = var.project_create != null ? local.iam_lod : {}
  iam_additive = var.project_create == null ? local.iam_lod : {}
  # group_iam    = local.group_iam_lod
  services = concat(var.project_services, [
    "bigquery.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudkms.googleapis.com",
    "compute.googleapis.com",
    "dataflow.googleapis.com",
    "dlp.googleapis.com",
    "pubsub.googleapis.com",
    "servicenetworking.googleapis.com",
    "storage.googleapis.com",
    "storage-component.googleapis.com"
  ])
  service_encryption_key_ids = {
    pubsub   = [try(local.service_encryption_keys.pubsub, null)]
    dataflow = [try(local.service_encryption_keys.dataflow, null)]
    storage  = [try(local.service_encryption_keys.storage, null)]
  }
  shared_vpc_service_config = local._shared_vpc_service_config
}

module "lod-vpc" {
  count      = var.network_config.network_self_link != null ? 0 : 1
  source     = "../../../modules/net-vpc"
  project_id = module.lod-prj.project_id
  name       = "${local.prefix_lod}-vpc"
  subnets = [
    {
      ip_cidr_range      = "10.10.0.0/24"
      name               = "${local.prefix_lod}-subnet"
      region             = var.location_config.region
      secondary_ip_range = {}
    }
  ]
}

module "lod-vpc-firewall" {
  count        = var.network_config.network_self_link != null ? 0 : 1
  source       = "../../../modules/net-vpc-firewall"
  project_id   = module.lod-prj.project_id
  network      = local._networks.load.network_name
  admin_ranges = ["10.10.0.0/24"]
}

module "lod-nat" {
  count          = var.network_config.network_self_link != null ? 0 : 1
  source         = "../../../modules/net-cloudnat"
  project_id     = module.lod-prj.project_id
  region         = var.location_config.region
  name           = "${local.prefix_lod}-default"
  router_network = module.lod-vpc[0].name
}
