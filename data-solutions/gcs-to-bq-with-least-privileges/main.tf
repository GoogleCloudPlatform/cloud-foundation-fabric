# Copyright 2021 Google LLC
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
  data_eng_users_iam = [
    for item in var.data_eng_users :
    "user:${item}"
  ]

  data_eng_groups_iam = [
    for item in var.data_eng_groups :
    "group:${item}"
  ]
}

###############################################################################
#                          Projects - Centralized                             #
###############################################################################

module "project-service" {
  source          = "../../modules/project"
  name            = var.project_name
  parent          = var.root_node
  billing_account = var.billing_account
  services = [
    "compute.googleapis.com",
    "servicenetworking.googleapis.com",
    "storage-component.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerystorage.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "dataflow.googleapis.com",
  ]
  iam = {
    # GCS roles
    "roles/storage.objectAdmin" = [
      module.service-account-df.iam_email,
      module.service-account-landing.iam_email
    ],
    "roles/storage.objectViewer" = [
      module.service-account-orch.iam_email,
    ],
    #Bigquery roles
    "roles/bigquery.admin" = [
      module.service-account-orch.iam_email,
    ]
    "roles/bigquery.dataEditor" = [
      module.service-account-df.iam_email,
    ]
    "roles/bigquery.dataViewer" = [
      module.service-account-bq.iam_email,
      module.service-account-orch.iam_email
    ]
    "roles/bigquery.jobUser" = [
      module.service-account-df.iam_email
    ]
    "roles/bigquery.user" = [
      module.service-account-bq.iam_email,
      module.service-account-df.iam_email
    ]
    #Common roles
    "roles/logging.logWriter" = [
      module.service-account-bq.iam_email,
      module.service-account-landing.iam_email,
      module.service-account-orch.iam_email,
    ]
    "roles/monitoring.metricWriter" = [
      module.service-account-bq.iam_email,
      module.service-account-landing.iam_email,
      module.service-account-orch.iam_email,
    ]
    "roles/iam.serviceAccountUser" = [
      module.service-account-orch.iam_email,
    ]
    "roles/iam.serviceAccountTokenCreator" = concat(
      local.data_eng_users_iam,
      local.data_eng_groups_iam
    )
    "roles/viewer" = concat(
      local.data_eng_users_iam,
      local.data_eng_groups_iam
    )
    #Dataflow roles
    "roles/dataflow.admin" = [
      module.service-account-orch.iam_email,
    ]
  }
  oslogin = true
}

###############################################################################
#                         Project Service Accounts                            #
###############################################################################

module "service-account-bq" {
  source     = "../../modules/iam-service-account"
  project_id = module.project-service.project_id
  name       = "bq-datalake"
  iam = {
    "roles/iam.serviceAccountTokenCreator" = concat(
      local.data_eng_users_iam,
      local.data_eng_groups_iam
    )
  }
}
module "service-account-landing" {
  source     = "../../modules/iam-service-account"
  project_id = module.project-service.project_id
  name       = "gcs-landing"
  iam = {
    "roles/iam.serviceAccountTokenCreator" = concat(
      local.data_eng_users_iam,
      local.data_eng_groups_iam
    )
  }
}

module "service-account-orch" {
  source     = "../../modules/iam-service-account"
  project_id = module.project-service.project_id
  name       = "orchestrator"
  iam = {
    "roles/iam.serviceAccountTokenCreator" = concat(
      local.data_eng_users_iam,
      local.data_eng_groups_iam
    )
  }
}

module "service-account-df" {
  source     = "../../modules/iam-service-account"
  project_id = module.project-service.project_id
  name       = "df-loading"
  iam_project_roles = {
    (var.project_name) = [
      "roles/dataflow.worker",
      "roles/bigquery.dataOwner",
      "roles/bigquery.metadataViewer",
      "roles/storage.objectViewer",
      "roles/bigquery.jobUser"
    ]
  }
  iam = {
    "roles/iam.serviceAccountTokenCreator" = concat(
      local.data_eng_users_iam,
      local.data_eng_groups_iam
    ),
    "roles/iam.serviceAccountUser" = concat(
      [module.service-account-orch.iam_email],
      local.data_eng_users_iam,
      local.data_eng_groups_iam
    )
  }
}

###############################################################################
#                                   Networking                                #
###############################################################################

module "vpc" {
  source     = "../../modules/net-vpc"
  project_id = module.project-service.project_id
  name       = var.vpc_name
  subnets = [
    {
      ip_cidr_range      = var.vpc_ip_cidr_range
      name               = var.vpc_subnet_name
      region             = var.region
      secondary_ip_range = {}
    }
  ]
}

module "vpc-firewall" {
  source       = "../../modules/net-vpc-firewall"
  project_id   = module.project-service.project_id
  network      = module.vpc.name
  admin_ranges = [var.vpc_ip_cidr_range]
}

module "nat" {
  source         = "../../modules/net-cloudnat"
  project_id     = module.project-service.project_id
  region         = var.region
  name           = "default"
  router_network = module.vpc.name
}

###############################################################################
#                                   GCS                                       #
###############################################################################

module "gcs-01" {
  source        = "../../modules/gcs"
  for_each      = toset(["data-landing", "df-tmplocation"])
  project_id    = module.project-service.project_id
  prefix        = module.project-service.project_id
  name          = each.key
  force_destroy = true
}

# module "gcs-02" {
#   source        = "../../modules/gcs-demo"
#   project_id    = module.project-service.project_id
#   prefix        = module.project-service.project_id
#   name          = "test-region"
#   location      = "europe-west1"
#   storage_class = "REGIONAL"
#   force_destroy = true
# }

###############################################################################
#                                   BQ                                        #
###############################################################################

module "bigquery-dataset" {
  source     = "../../modules/bigquery-dataset"
  project_id = module.project-service.project_id
  id         = "datalake"
  tables = {
    person = {
      friendly_name = "Person. Dataflow import."
      labels        = {}
      options       = null
      partitioning = {
        field = null
        range = null # use start/end/interval for range
        time  = null
      }
      schema              = file("${path.module}/person.json")
      deletion_protection = false
    }
  }
}
