/**
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

###############################################################################
#                                   projects                                  #
###############################################################################

module "project-datamart" {
  source          = "../../../modules/project"
  parent          = var.root_node
  billing_account = var.billing_account_id
  prefix          = var.prefix
  name            = var.project_names.datamart
  services = [
    "bigtable.googleapis.com",
    "bigtableadmin.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerystorage.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "storage-component.googleapis.com",
  ]
  iam = {
    "roles/editor" = [module.sa-services-main.iam_email]
  }
}

module "project-dwh" {
  source          = "../../../modules/project"
  parent          = var.root_node
  billing_account = var.billing_account_id
  prefix          = var.prefix
  name            = var.project_names.dwh
  services = [
    "bigquery.googleapis.com",
    "bigquerystorage.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "storage-component.googleapis.com",
  ]
  iam = {
    "roles/editor" = [module.sa-services-main.iam_email]
  }
}

module "project-landing" {
  source          = "../../../modules/project"
  parent          = var.root_node
  billing_account = var.billing_account_id
  prefix          = var.prefix
  name            = var.project_names.landing
  services = [
    "pubsub.googleapis.com",
    "storage-component.googleapis.com",
  ]
  iam = {
    "roles/editor" = [module.sa-services-main.iam_email]
  }
}

module "project-services" {
  source          = "../../../modules/project"
  parent          = var.root_node
  billing_account = var.billing_account_id
  prefix          = var.prefix
  name            = var.project_names.services
  services = [
    "storage-component.googleapis.com",
    "sourcerepo.googleapis.com",
    "stackdriver.googleapis.com",
    "cloudasset.googleapis.com",
  ]
  iam = {
    "roles/editor" = [module.sa-services-main.iam_email]
  }
}

module "project-transformation" {
  source          = "../../../modules/project"
  parent          = var.root_node
  billing_account = var.billing_account_id
  prefix          = var.prefix
  name            = var.project_names.transformation
  services = [
    "cloudbuild.googleapis.com",
    "compute.googleapis.com",
    "dataflow.googleapis.com",
    "servicenetworking.googleapis.com",
    "storage-component.googleapis.com",
  ]
  iam = {
    "roles/editor" = [module.sa-services-main.iam_email]
  }
}

###############################################################################
#                               service accounts                              #
###############################################################################

module "sa-services-main" {
  source     = "../../../modules/iam-service-account"
  project_id = module.project-services.project_id
  name       = var.service_account_names.main
}
