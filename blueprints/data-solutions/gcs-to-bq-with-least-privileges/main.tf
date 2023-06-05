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

locals {
  iam = {
    "roles/iam.serviceAccountUser" = [
      module.service-account-orch.iam_email
    ]
    # GCS roles
    "roles/storage.objectAdmin" = [
      module.service-account-df.iam_email,
      module.service-account-landing.iam_email
    ],
    # BigQuery roles
    "roles/bigquery.dataOwner" = [
      module.service-account-df.iam_email
    ]
    "roles/bigquery.dataViewer" = [
      module.service-account-bq.iam_email
    ]
    "roles/bigquery.jobUser" = [
      module.service-account-bq.iam_email
    ]
    # Dataflow roles
    "roles/dataflow.admin" = [
      module.service-account-orch.iam_email
    ]
    "roles/dataflow.worker" = [
      module.service-account-df.iam_email,
    ]
  }
  group_iam = {
    for group in var.data_eng_principals :
    group => [
      "roles/bigquery.admin",
      "roles/compute.viewer",
      "roles/dataflow.admin",
      "roles/dataflow.developer",
      "roles/iam.serviceAccountTokenCreator"
    ]
  }
  network_subnet_selflink = try(
    module.vpc[0].subnets["${var.region}/subnet"].self_link,
    var.network_config.subnet_self_link
  )
  shared_vpc_bindings = {
    "roles/compute.networkUser" = [
      "robot-df", "sa-df-worker"
    ]
  }
}

module "project" {
  source          = "../../../modules/project"
  name            = var.project_config.project_id
  parent          = var.project_config.parent
  billing_account = var.project_config.billing_account_id
  project_create  = var.project_config.billing_account_id != null
  prefix          = var.project_config.billing_account_id == null ? null : var.prefix
  services = [
    "bigquery.googleapis.com",
    "bigquerystorage.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "cloudkms.googleapis.com",
    "compute.googleapis.com",
    "dataflow.googleapis.com",
    "servicenetworking.googleapis.com",
    "storage.googleapis.com",
    "storage-component.googleapis.com",
  ]
  group_iam    = local.group_iam
  iam          = var.project_config.billing_account_id != null ? local.iam : {}
  iam_additive = var.project_config.billing_account_id == null ? local.iam : {}
  shared_vpc_service_config = var.network_config.host_project == null ? null : {
    attach       = true
    host_project = var.network_config.host_project
    service_identity_iam = {
      "roles/compute.networkUser" = ["dataflow"]
    }
  }
}
