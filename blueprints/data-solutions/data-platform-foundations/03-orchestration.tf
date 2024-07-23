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

# tfdoc:file:description Orchestration project and VPC.

locals {
  orch_iam = {
    data_engineers = [
      "roles/artifactregistry.admin",
      "roles/bigquery.dataEditor",
      "roles/bigquery.jobUser",
      "roles/cloudbuild.builds.editor",
      "roles/composer.admin",
      "roles/composer.user",
      "roles/composer.environmentAndStorageObjectAdmin",
      "roles/iam.serviceAccountUser",
      "roles/iap.httpsResourceAccessor",
      "roles/serviceusage.serviceUsageConsumer",
      "roles/storage.objectAdmin"
    ]
    robots_cloudbuild = [
      "roles/storage.objectAdmin"
    ]
    robots_composer = [
      "roles/composer.ServiceAgentV2Ext",
      "roles/storage.objectAdmin"
    ]
    sa_df_build = [
      "roles/cloudbuild.serviceAgent",
      "roles/storage.objectAdmin"
    ]
    sa_load = [
      "roles/artifactregistry.reader",
      "roles/bigquery.dataEditor",
      "roles/storage.objectViewer"
    ]
    sa_orch = [
      "roles/bigquery.jobUser",
      "roles/composer.worker",
      "roles/iam.serviceAccountUser",
      "roles/storage.objectAdmin"
    ]
    sa_transf_df = [
      "roles/bigquery.dataEditor"
    ]
  }
}

module "orch-project" {
  source          = "../../../modules/project"
  parent          = var.project_config.parent
  billing_account = var.project_config.billing_account_id
  project_create  = var.project_config.project_create
  prefix          = local.use_projects ? null : var.prefix
  name = (
    local.use_projects
    ? var.project_config.project_ids.orc
    : "${var.project_config.project_ids.orc}${local.project_suffix}"
  )
  iam                   = local.use_projects ? {} : local.orch_iam_auth
  iam_bindings_additive = !local.use_projects ? {} : local.orch_iam_additive

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
    "datalineage.googleapis.com",
    "orgpolicy.googleapis.com",
    "pubsub.googleapis.com",
    "servicenetworking.googleapis.com",
    "storage.googleapis.com",
    "storage-component.googleapis.com"
  ])
  service_encryption_key_ids = {
    "composer.googleapis.com" = compact([var.service_encryption_keys.composer])
    "storage.googleapis.com"  = compact([var.service_encryption_keys.storage])
  }
  shared_vpc_service_config = local.shared_vpc_project == null ? null : {
    attach       = true
    host_project = local.shared_vpc_project
  }
}

module "orch-cs-0" {
  source         = "../../../modules/gcs"
  project_id     = module.orch-project.project_id
  prefix         = var.prefix
  name           = "orc-cs-0"
  location       = var.location
  storage_class  = "MULTI_REGIONAL"
  encryption_key = var.service_encryption_keys.storage
  force_destroy  = !var.deletion_protection
}

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
  network    = module.orch-vpc[0].name
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
  router_network = module.orch-vpc[0].name
}

module "orch-artifact-reg" {
  source      = "../../../modules/artifact-registry"
  project_id  = module.orch-project.project_id
  name        = "${var.prefix}-app-images"
  location    = var.region
  description = "Docker repository storing application images e.g. Dataflow, Cloud Run etc..."
  format      = { docker = { standard = {} } }
}

module "orch-cs-df-template" {
  source         = "../../../modules/gcs"
  project_id     = module.orch-project.project_id
  prefix         = var.prefix
  name           = "orc-cs-df-template"
  location       = var.location
  storage_class  = "MULTI_REGIONAL"
  encryption_key = var.service_encryption_keys.storage
  force_destroy  = !var.deletion_protection
}

module "orch-cs-build-staging" {
  source         = "../../../modules/gcs"
  project_id     = module.orch-project.project_id
  prefix         = var.prefix
  name           = "orc-cs-build-staging"
  location       = var.location
  storage_class  = "MULTI_REGIONAL"
  encryption_key = var.service_encryption_keys.storage
  force_destroy  = !var.deletion_protection
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
