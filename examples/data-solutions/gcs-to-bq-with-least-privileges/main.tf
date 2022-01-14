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
#                                 Projects                                    #
###############################################################################

module "project-service" {
  source          = "../../../modules/project"
  name            = var.project_name
  parent          = var.root_node
  billing_account = var.billing_account
  project_create  = var.project_create
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
    )
    "roles/viewer" = concat(
      local.data_eng_users_iam,
    )
    #Dataflow roles
    "roles/dataflow.admin" = [
      module.service-account-orch.iam_email,
    ]
    "roles/dataflow.worker" = [
      module.service-account-df.iam_email,
    ]
    #Network roles
    "roles/compute.networkUser" = [
      module.service-account-df.iam_email,
      "serviceAccount:${module.project-service.service_accounts.robots.dataflow}"
    ]
  }
  group_iam = {
    "roles/iam.serviceAccountTokenCreator" = concat(
      local.data_eng_groups_iam
    )
    "roles/viewer" = concat(
      local.data_eng_groups_iam
    )
  }
}
