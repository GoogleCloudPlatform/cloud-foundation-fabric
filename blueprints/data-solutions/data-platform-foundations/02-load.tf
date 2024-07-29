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

# tfdoc:file:description Load project and VPC.

locals {
  load_iam = {
    data_engineers = [
      "roles/dataflow.admin",
      "roles/dataflow.developer"
    ]
    robots_dataflow_load = [
      "roles/storage.objectAdmin"
    ]
    sa_load = [
      "roles/bigquery.jobUser",
      "roles/dataflow.admin",
      "roles/dataflow.worker",
      "roles/storage.objectAdmin"
    ]
    sa_orch = [
      "roles/dataflow.admin"
    ]
  }
}

module "load-project" {
  source          = "../../../modules/project"
  parent          = var.project_config.parent
  billing_account = var.project_config.billing_account_id
  project_create  = var.project_config.project_create
  prefix          = local.use_projects ? null : var.prefix
  name = (
    local.use_projects
    ? var.project_config.project_ids.load
    : "${var.project_config.project_ids.load}${local.project_suffix}"
  )
  iam                   = local.use_projects ? {} : local.load_iam_auth
  iam_bindings_additive = !local.use_projects ? {} : local.load_iam_additive
  services = concat(var.project_services, [
    "bigquery.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudkms.googleapis.com",
    "compute.googleapis.com",
    "dataflow.googleapis.com",
    "datalineage.googleapis.com",
    "dlp.googleapis.com",
    "pubsub.googleapis.com",
    "servicenetworking.googleapis.com",
    "storage.googleapis.com",
    "storage-component.googleapis.com"
  ])
  service_encryption_key_ids = {
    "pubsub.googleapis.com"   = compact([var.service_encryption_keys.pubsub])
    "dataflow.googleapis.com" = compact([var.service_encryption_keys.dataflow])
    "storage.googleapis.com"  = compact([var.service_encryption_keys.storage])
  }
  shared_vpc_service_config = local.shared_vpc_project == null ? null : {
    attach       = true
    host_project = local.shared_vpc_project
  }
}

module "load-sa-df-0" {
  source       = "../../../modules/iam-service-account"
  project_id   = module.load-project.project_id
  prefix       = var.prefix
  name         = "load-df-0"
  display_name = "Data platform Dataflow load service account"
  iam = {
    "roles/iam.serviceAccountTokenCreator" = [
      local.groups_iam.data-engineers,
      module.orch-sa-cmp-0.iam_email
    ],
    "roles/iam.serviceAccountUser" = [
      module.orch-sa-cmp-0.iam_email
    ]
  }
}

module "load-cs-df-0" {
  source         = "../../../modules/gcs"
  project_id     = module.load-project.project_id
  prefix         = var.prefix
  name           = "load-cs-0"
  location       = var.location
  storage_class  = "MULTI_REGIONAL"
  encryption_key = var.service_encryption_keys.storage
  force_destroy  = !var.deletion_protection
}

module "load-vpc" {
  source     = "../../../modules/net-vpc"
  count      = local.use_shared_vpc ? 0 : 1
  project_id = module.load-project.project_id
  name       = "${var.prefix}-lod"
  subnets = [
    {
      ip_cidr_range = "10.10.0.0/24"
      name          = "${var.prefix}-lod"
      region        = var.region
    }
  ]
}

module "load-vpc-firewall" {
  source     = "../../../modules/net-vpc-firewall"
  count      = local.use_shared_vpc ? 0 : 1
  project_id = module.load-project.project_id
  network    = module.load-vpc[0].name
  default_rules_config = {
    admin_ranges = ["10.10.0.0/24"]
  }
}

module "load-nat" {
  source         = "../../../modules/net-cloudnat"
  count          = local.use_shared_vpc ? 0 : 1
  project_id     = module.load-project.project_id
  name           = "${var.prefix}-lod"
  region         = var.region
  router_network = module.load-vpc[0].name
}
