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

# tfdoc:file:description Orchestration project and VPC.

locals {
  iam_orch = {
    "roles/artifactregistry.admin"  = [local.groups_iam.data-engineers]
    "roles/artifactregistry.reader" = [module.load-sa-df-0.iam_email]
    "roles/bigquery.dataEditor" = [
      module.load-sa-df-0.iam_email,
      module.transf-sa-df-0.iam_email,
      local.groups_iam.data-engineers
    ]
    "roles/bigquery.jobUser" = [
      module.orch-sa-cmp-0.iam_email,
      local.groups_iam.data-engineers
    ]
    "roles/cloudbuild.builds.editor"                  = [local.groups_iam.data-engineers]
    "roles/cloudbuild.serviceAgent"                   = [module.orch-sa-df-build.iam_email]
    "roles/composer.admin"                            = [local.groups_iam.data-engineers]
    "roles/composer.environmentAndStorageObjectAdmin" = [local.groups_iam.data-engineers]
    "roles/composer.ServiceAgentV2Ext" = [
      "serviceAccount:${module.orch-project.service_accounts.robots.composer}"
    ]
    "roles/composer.worker" = [
      module.orch-sa-cmp-0.iam_email
    ]
    "roles/iam.serviceAccountUser" = [
      module.orch-sa-cmp-0.iam_email, local.groups_iam.data-engineers
    ]
    "roles/iap.httpsResourceAccessor"         = [local.groups_iam.data-engineers]
    "roles/serviceusage.serviceUsageConsumer" = [local.groups_iam.data-engineers]
    "roles/storage.objectAdmin" = [
      module.orch-sa-cmp-0.iam_email,
      module.orch-sa-df-build.iam_email,
      "serviceAccount:${module.orch-project.service_accounts.robots.composer}",
      "serviceAccount:${module.orch-project.service_accounts.robots.cloudbuild}",
      local.groups_iam.data-engineers
    ]
    "roles/storage.objectViewer" = [module.load-sa-df-0.iam_email]
  }
  orch_subnet = (
    local.use_shared_vpc
    ? var.network_config.subnet_self_links.orchestration
    : values(module.orch-vpc.0.subnet_self_links)[0]
  )
  orch_vpc = (
    local.use_shared_vpc
    ? var.network_config.network_self_link
    : module.orch-vpc.0.self_link
  )

  # Note: This formatting is needed for output purposes since the fabric artifact registry
  # module doesn't yet expose the docker usage path of a registry folder in the needed format.
  orch_docker_path = format("%s-docker.pkg.dev/%s/%s",
  var.region, module.orch-project.project_id, module.orch-artifact-reg.name)
}

module "orch-project" {
  source          = "../../../modules/project"
  parent          = var.project_config.parent
  billing_account = var.project_config.billing_account_id
  project_create  = var.project_config.billing_account_id != null
  prefix          = var.project_config.billing_account_id == null ? null : var.prefix
  name            = var.project_config.billing_account_id == null ? var.project_config.project_ids.orc : "${var.project_config.project_ids.orc}${local.project_suffix}"
  iam             = var.project_config.billing_account_id != null ? local.iam_orch : null
  iam_additive    = var.project_config.billing_account_id == null ? local.iam_orch : null
  oslogin         = false
  services = concat(var.project_services, [
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudkms.googleapis.com",
    "composer.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "containerregistry.googleapis.com",
    "artifactregistry.googleapis.com",
    "dataflow.googleapis.com",
    "orgpolicy.googleapis.com",
    "pubsub.googleapis.com",
    "servicenetworking.googleapis.com",
    "storage.googleapis.com",
    "storage-component.googleapis.com"
  ])
  service_encryption_key_ids = {
    composer = [try(local.service_encryption_keys.composer, null)]
    storage  = [try(local.service_encryption_keys.storage, null)]
  }
  shared_vpc_service_config = local.shared_vpc_project == null ? null : {
    attach       = true
    host_project = local.shared_vpc_project
  }
}

# Cloud Storage

module "orch-cs-0" {
  source         = "../../../modules/gcs"
  project_id     = module.orch-project.project_id
  prefix         = var.prefix
  name           = "orc-cs-0"
  location       = var.location
  storage_class  = "MULTI_REGIONAL"
  encryption_key = try(local.service_encryption_keys.storage, null)
}

# internal VPC resources

module "orch-vpc" {
  source     = "../../../modules/net-vpc"
  count      = local.use_shared_vpc ? 0 : 1
  project_id = module.orch-project.project_id
  name       = "${var.prefix}-orch"
  subnets = [
    {
      ip_cidr_range = "10.10.0.0/24"
      name          = "${var.prefix}-orch"
      region        = var.region
      secondary_ip_ranges = {
        pods     = "10.10.8.0/22"
        services = "10.10.12.0/24"
      }
    }
  ]
}

module "orch-vpc-firewall" {
  source     = "../../../modules/net-vpc-firewall"
  count      = local.use_shared_vpc ? 0 : 1
  project_id = module.orch-project.project_id
  network    = module.orch-vpc.0.name
  default_rules_config = {
    admin_ranges = ["10.10.0.0/24"]
  }
}

module "orch-nat" {
  count          = local.use_shared_vpc ? 0 : 1
  source         = "../../../modules/net-cloudnat"
  project_id     = module.orch-project.project_id
  name           = "${var.prefix}-orch"
  region         = var.region
  router_network = module.orch-vpc.0.name
}

module "orch-artifact-reg" {
  source      = "../../../modules/artifact-registry"
  project_id  = module.orch-project.project_id
  id          = "${var.prefix}-app-images"
  location    = var.region
  format      = "DOCKER"
  description = "Docker repository storing application images e.g. Dataflow, Cloud Run etc..."
}

module "orch-cs-df-template" {
  source         = "../../../modules/gcs"
  project_id     = module.orch-project.project_id
  prefix         = var.prefix
  name           = "orc-cs-df-template"
  location       = var.region
  storage_class  = "REGIONAL"
  encryption_key = try(local.service_encryption_keys.storage, null)
}

module "orch-cs-build-staging" {
  source         = "../../../modules/gcs"
  project_id     = module.orch-project.project_id
  prefix         = var.prefix
  name           = "orc-cs-build-staging"
  location       = var.region
  storage_class  = "REGIONAL"
  encryption_key = try(local.service_encryption_keys.storage, null)
}

module "orch-sa-df-build" {
  source       = "../../../modules/iam-service-account"
  project_id   = module.orch-project.project_id
  prefix       = var.prefix
  name         = "orc-sa-df-build"
  display_name = "Data platform Dataflow build service account"
  # Note values below should pertain to the system / group / users who are able to 
  # invoke the build via this service account
  iam = {
    "roles/iam.serviceAccountTokenCreator" = [local.groups_iam.data-engineers]
    "roles/iam.serviceAccountUser"         = [local.groups_iam.data-engineers]
  }
}
