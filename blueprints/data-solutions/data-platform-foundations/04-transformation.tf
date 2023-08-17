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

# tfdoc:file:description Transformation project and VPC.

locals {
  iam_trf = {
    "roles/bigquery.jobUser" = [
      module.transf-sa-bq-0.iam_email, local.groups_iam.data-engineers
    ]
    "roles/dataflow.admin" = [
      module.orch-sa-cmp-0.iam_email, local.groups_iam.data-engineers
    ]
    "roles/dataflow.worker" = [module.transf-sa-df-0.iam_email]
    "roles/storage.objectAdmin" = [
      module.transf-sa-df-0.iam_email,
      "serviceAccount:${module.transf-project.service_accounts.robots.dataflow}"
    ]
  }
  # this only works because the service account module uses a static output
  iam_trf_additive = {
    for k in flatten([
      for role, members in local.iam_trf : [
        for member in members : {
          role   = role
          member = member
        }
      ]
    ]) : "{k.member}-{k.role}" => k
  }
  transf_subnet = (
    local.use_shared_vpc
    ? var.network_config.subnet_self_links.orchestration
    : values(module.transf-vpc.0.subnet_self_links)[0]
  )
  transf_vpc = (
    local.use_shared_vpc
    ? var.network_config.network_self_link
    : module.transf-vpc.0.self_link
  )
}

module "transf-project" {
  source          = "../../../modules/project"
  parent          = var.project_config.parent
  billing_account = var.project_config.billing_account_id
  project_create  = var.project_config.billing_account_id != null
  prefix = (
    var.project_config.billing_account_id == null ? null : var.prefix
  )
  name = (
    var.project_config.billing_account_id == null
    ? var.project_config.project_ids.trf
    : "${var.project_config.project_ids.trf}${local.project_suffix}"
  )
  iam = (
    var.project_config.billing_account_id == null ? {} : local.iam_trf
  )
  iam_bindings_additive = (
    var.project_config.billing_account_id != null ? {} : local.iam_trf_additive
  )
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
    dataflow = [try(local.service_encryption_keys.dataflow, null)]
    storage  = [try(local.service_encryption_keys.storage, null)]
  }
  shared_vpc_service_config = local.shared_vpc_project == null ? null : {
    attach       = true
    host_project = local.shared_vpc_project
  }
}

# Cloud Storage

module "transf-sa-df-0" {
  source       = "../../../modules/iam-service-account"
  project_id   = module.transf-project.project_id
  prefix       = var.prefix
  name         = "trf-df-0"
  display_name = "Data platform Dataflow transformation service account"
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

module "transf-cs-df-0" {
  source         = "../../../modules/gcs"
  project_id     = module.transf-project.project_id
  prefix         = var.prefix
  name           = "trf-cs-0"
  location       = var.location
  storage_class  = "MULTI_REGIONAL"
  encryption_key = try(local.service_encryption_keys.storage, null)
}

# BigQuery

module "transf-sa-bq-0" {
  source       = "../../../modules/iam-service-account"
  project_id   = module.transf-project.project_id
  prefix       = var.prefix
  name         = "trf-bq-0"
  display_name = "Data platform BigQuery transformation service account"
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

# internal VPC resources

module "transf-vpc" {
  source     = "../../../modules/net-vpc"
  count      = local.use_shared_vpc ? 0 : 1
  project_id = module.transf-project.project_id
  name       = "${var.prefix}-trf"
  subnets = [
    {
      ip_cidr_range = "10.10.0.0/24"
      name          = "${var.prefix}-trf"
      region        = var.region
    }
  ]
}

module "transf-vpc-firewall" {
  source     = "../../../modules/net-vpc-firewall"
  count      = local.use_shared_vpc ? 0 : 1
  project_id = module.transf-project.project_id
  network    = module.transf-vpc.0.name
  default_rules_config = {
    admin_ranges = ["10.10.0.0/24"]
  }
}

module "transf-nat" {
  source         = "../../../modules/net-cloudnat"
  count          = local.use_shared_vpc ? 0 : 1
  project_id     = module.transf-project.project_id
  name           = "${var.prefix}-trf"
  region         = var.region
  router_network = module.transf-vpc.0.name
}
