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

# tfdoc:file:description Core resources.

locals {
  iam = {
    "roles/servicedirectory.viewer" = [
      "serviceAccount:${module.project.service_accounts.robots.dialogflow}"
    ],
    "roles/servicedirectory.pscAuthorizedService" = [
      "serviceAccount:${module.project.service_accounts.robots.dialogflow}"
    ],
    "roles/run.invoker" = [
      "serviceAccount:${module.project.service_accounts.robots.dialogflow}"
    ],
    "roles/storage.objectCreator" = [
      "serviceAccount:${module.project.service_accounts.robots.cloudbuild-builder}"
    ]
    "roles/artifactregistry.writer" = [
      "serviceAccount:${module.project.service_accounts.robots.cloudbuild-builder}"
    ]
    "roles/storage.objectCreator" = [
      "serviceAccount:${module.project.service_accounts.robots.cloudbuild}"
    ]
    "roles/artifactregistry.writer" = [
      "serviceAccount:${module.project.service_accounts.robots.cloudbuild}"
    ]

  }

  subnets = (
    local.use_shared_vpc
    ? var.network_config.subnets_self_link
    : { for k, v in module.vpc.0.subnet_ids : split("/", k)[1] => v }
  )
  use_shared_vpc = var.network_config.host_project != null
  vpc = (
    local.use_shared_vpc
    ? var.network_config.network_self_link
    : module.vpc.0.self_link
  )
  vpc_project = (
    local.use_shared_vpc
    ? var.network_config.host_project
    : module.project.project_id
  )
}

module "project" {
  source = "../../../modules/project"
  name = (
    var.project_config.billing_account_id == null
    ? var.project_config.project_id
    : var.project_config.project_id
  )
  parent          = var.project_config.parent
  billing_account = var.project_config.billing_account_id
  project_create  = var.project_config.billing_account_id != null
  prefix = (
    var.project_config.billing_account_id == null ? null : var.prefix
  )
  services = [
    "cloudbuild.googleapis.com",
    "compute.googleapis.com",
    "dialogflow.googleapis.com",
    "networkmanagement.googleapis.com",
    "run.googleapis.com",
    "servicedirectory.googleapis.com",
    "servicenetworking.googleapis.com",
    "stackdriver.googleapis.com",
    "vpcaccess.googleapis.com"
  ]
  iam = local.iam
  shared_vpc_service_config = var.network_config.host_project == null ? null : {
    attach       = true
    host_project = var.network_config.host_project
    service_identity_iam = {
      "roles/servicedirectory.pscAuthorizedService" = [
        module.project.service_accounts.robots.dialogflow
      ]
    }
  }
  service_encryption_key_ids = {} #TODO
  service_config = {
    disable_on_destroy         = false
    disable_dependent_services = false
  }
}
