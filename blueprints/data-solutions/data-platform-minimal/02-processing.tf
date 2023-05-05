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

# tfdoc:file:description Processing project and VPC.

locals {
  iam_processing = {
    "roles/composer.admin"                            = [local.groups_iam.data-engineers]
    "roles/composer.environmentAndStorageObjectAdmin" = [local.groups_iam.data-engineers]
    "roles/composer.ServiceAgentV2Ext" = [
      "serviceAccount:${module.processing-project.service_accounts.robots.composer}"
    ]
    "roles/composer.worker" = [
      module.processing-sa-cmp-0.iam_email
    ]
    "roles/dataproc.editor" = [
      module.processing-sa-cmp-0.iam_email
    ]
    "roles/dataproc.worker" = [
      module.processing-sa-dp-0.iam_email
    ]
    "roles/iam.serviceAccountUser" = [
      module.processing-sa-cmp-0.iam_email, local.groups_iam.data-engineers
    ]
    "roles/iap.httpsResourceAccessor"         = [local.groups_iam.data-engineers]
    "roles/serviceusage.serviceUsageConsumer" = [local.groups_iam.data-engineers]
    "roles/storage.admin" = [
      module.processing-sa-cmp-0.iam_email,
      "serviceAccount:${module.processing-project.service_accounts.robots.composer}",
      local.groups_iam.data-engineers
    ]
  }
  processing_subnet = (
    local.use_shared_vpc
    ? var.network_config.subnet_self_links.processingestration
    : values(module.processing-vpc.0.subnet_self_links)[0]
  )
  processing_vpc = (
    local.use_shared_vpc
    ? var.network_config.network_self_link
    : module.processing-vpc.0.self_link
  )


}

module "processing-project" {
  source          = "../../../modules/project"
  parent          = var.project_config.parent
  billing_account = var.project_config.billing_account_id
  project_create  = var.project_config.billing_account_id != null
  prefix          = var.project_config.billing_account_id == null ? null : var.prefix
  name            = var.project_config.billing_account_id == null ? var.project_config.project_ids.processing : "${var.project_config.project_ids.processing}${local.project_suffix}"
  iam             = var.project_config.billing_account_id != null ? local.iam_processing : null
  iam_additive    = var.project_config.billing_account_id == null ? local.iam_processing : null
  oslogin         = false
  services = concat(var.project_services, [
    "bigquery.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudkms.googleapis.com",
    "composer.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "dataproc.googleapis.com",
    "servicenetworking.googleapis.com",
    "storage.googleapis.com",
    "storage-component.googleapis.com"
  ])
  service_encryption_key_ids = {
    composer = [try(local.service_encryption_keys.composer, null)]
    compute  = [try(local.service_encryption_keys.compute, null)]
    storage  = [try(local.service_encryption_keys.storage, null)]
  }
  shared_vpc_service_config = local.shared_vpc_project == null ? null : {
    attach       = true
    host_project = local.shared_vpc_project
  }
}

# Cloud Storage

module "processing-cs-0" {
  source         = "../../../modules/gcs"
  project_id     = module.processing-project.project_id
  prefix         = var.prefix
  name           = "prc-cs-0"
  location       = var.location
  storage_class  = "MULTI_REGIONAL"
  encryption_key = try(local.service_encryption_keys.storage, null)
}

# internal VPC resources

module "processing-vpc" {
  source     = "../../../modules/net-vpc"
  count      = local.use_shared_vpc ? 0 : 1
  project_id = module.processing-project.project_id
  name       = "${var.prefix}-processing"
  subnets = [
    {
      ip_cidr_range = "10.10.0.0/24"
      name          = "${var.prefix}-processing"
      region        = var.region
      secondary_ip_ranges = {
        pods     = "10.10.8.0/22"
        services = "10.10.12.0/24"
      }
    }
  ]
}

module "processing-vpc-firewall" {
  source     = "../../../modules/net-vpc-firewall"
  count      = local.use_shared_vpc ? 0 : 1
  project_id = module.processing-project.project_id
  network    = module.processing-vpc.0.name
  default_rules_config = {
    admin_ranges = ["10.10.0.0/24"]
  }
}

module "processing-nat" {
  count          = local.use_shared_vpc ? 0 : 1
  source         = "../../../modules/net-cloudnat"
  project_id     = module.processing-project.project_id
  name           = "${var.prefix}-processing"
  region         = var.region
  router_network = module.processing-vpc.0.name
}
