# Copyright 2023 Google LLC
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
  iam_prc = {
    "roles/bigquery.jobUser" = [
      module.processing-sa-cmp-0.iam_email,
      module.processing-sa-0.iam_email
    ]
    "roles/composer.admin" = [
      local.groups_iam.data-engineers
    ]
    "roles/dataflow.admin" = [
      module.processing-sa-cmp-0.iam_email
    ]
    "roles/dataflow.worker" = [
      module.processing-sa-0.iam_email
    ]
    "roles/composer.environmentAndStorageObjectAdmin" = [
      local.groups_iam.data-engineers
    ]
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
      module.processing-sa-0.iam_email
    ]
    "roles/iam.serviceAccountUser" = [
      module.processing-sa-cmp-0.iam_email,
      local.groups_iam.data-engineers
    ]
    "roles/iap.httpsResourceAccessor" = [
      local.groups_iam.data-engineers
    ]
    "roles/serviceusage.serviceUsageConsumer" = [
      local.groups_iam.data-engineers
    ]
    "roles/storage.admin" = [
      module.processing-sa-cmp-0.iam_email,
      "serviceAccount:${module.processing-project.service_accounts.robots.composer}",
      local.groups_iam.data-engineers
    ]
  }
  # this only works because the service account module uses a static output
  iam_prc_additive = {
    for k in flatten([
      for role, members in local.iam_prc : [
        for member in members : {
          role   = role
          member = member
        }
      ]
    ]) : "${k.member}-${k.role}" => k
  }
  processing_subnet = (
    local.use_shared_vpc
    ? var.network_config.subnet_self_link
    : try(
      module.processing-vpc.0.subnet_self_links["${var.region}/${var.prefix}-processing"],
      null
    )
  )
  processing_vpc = (
    local.use_shared_vpc
    ? var.network_config.network_self_link
    : try(module.processing-vpc.0.self_link, null)
  )
}

module "processing-project" {
  source          = "../../../modules/project"
  parent          = var.project_config.parent
  billing_account = var.project_config.billing_account_id
  project_create  = var.project_config.billing_account_id != null
  prefix = (
    var.project_config.billing_account_id == null ? null : var.prefix
  )
  name = (
    var.project_config.billing_account_id == null
    ? var.project_config.project_ids.processing
    : "${var.project_config.project_ids.processing}${local.project_suffix}"
  )
  iam = (
    var.project_config.billing_account_id == null ? {} : local.iam_prc
  )
  iam_bindings_additive = (
    var.project_config.billing_account_id != null ? {} : local.iam_prc_additive
  )

  services = [
    "bigquery.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "composer.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "dataflow.googleapis.com",
    "datalineage.googleapis.com",
    "dataproc.googleapis.com",
    "iam.googleapis.com",
    "servicenetworking.googleapis.com",
    "serviceusage.googleapis.com",
    "stackdriver.googleapis.com",
    "storage.googleapis.com",
    "storage-component.googleapis.com"
  ]
  service_encryption_key_ids = {
    composer = [var.service_encryption_keys.composer]
    compute  = [var.service_encryption_keys.compute]
    storage  = [var.service_encryption_keys.storage]
  }
  shared_vpc_service_config = var.network_config.host_project == null ? null : {
    attach       = true
    host_project = var.network_config.host_project
    service_identity_iam = {
      "roles/compute.networkUser" = [
        "cloudservices", "compute", "container-engine", "dataflow", "dataproc"
      ]
      "roles/composer.sharedVpcAgent" = [
        "composer"
      ]
      "roles/container.hostServiceAgentUser" = [
        "container-engine"
      ]
    }
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
  encryption_key = var.service_encryption_keys.storage
  force_destroy  = !var.deletion_protection
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
