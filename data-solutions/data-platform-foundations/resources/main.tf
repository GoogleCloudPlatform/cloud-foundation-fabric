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

locals {
  module_version = "4.2.0"

  landing_pubsub = merge({
    for k, v in var.landing_pubsub :
    k => {
      name          = v.name
      subscriptions = v.subscriptions
      subscription_iam = merge({
        for s_k, s_v in v.subscription_iam :
        s_k => merge(s_v, { "roles/pubsub.subscriber" : ["serviceAccount:${module.transformation-default-service-accounts.email}"] })
      })
    }
  })
}

###############################################################################
#                                 Projects                                    #
###############################################################################
module "project-datamart" {
  source         = "../../../modules/project"
  name           = var.project_ids.datamart
  project_create = false
}

module "project-dwh" {
  source         = "../../../modules/project"
  name           = var.project_ids.dwh
  project_create = false
}

module "project-landing" {
  source         = "../../../modules/project"
  name           = var.project_ids.landing
  project_create = false
}

module "project-services" {
  source         = "../../../modules/project"
  name           = var.project_ids.services
  project_create = false
}

module "project-transformation" {
  source         = "../../../modules/project"
  name           = var.project_ids.transformation
  project_create = false
}

###############################################################################
#                                   IAM                                       #
###############################################################################

module "datamart-default-service-accounts" {
  source     = "../../../modules/iam-service-account"
  project_id = module.project-datamart.project_id
  name       = var.project_service_account.datamart

  iam_project_roles = {
    "${module.project-datamart.project_id}" = [
      "roles/editor",
    ]
  }
}

module "dwh-default-service-accounts" {
  source     = "../../../modules/iam-service-account"
  project_id = module.project-dwh.project_id
  name       = var.project_service_account.dwh
}

module "landing-default-service-accounts" {
  source     = "../../../modules/iam-service-account"
  project_id = module.project-landing.project_id
  name       = var.project_service_account.landing

  iam_project_roles = {
    "${module.project-landing.project_id}" = [
      "roles/pubsub.publisher",
    ]
  }
}

module "services-default-service-accounts" {
  source     = "../../../modules/iam-service-account"
  project_id = module.project-services.project_id
  name       = var.project_service_account.services

  iam_project_roles = {
    "${module.project-services.project_id}" = [
      "roles/editor",
    ]
  }
}

module "transformation-default-service-accounts" {
  source     = "../../../modules/iam-service-account"
  project_id = module.project-transformation.project_id
  name       = var.project_service_account.transformation

  iam_project_roles = {
    "${module.project-transformation.project_id}" = [
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
      "roles/dataflow.admin",
      "roles/iam.serviceAccountUser",
      "roles/bigquery.dataOwner",
      "roles/bigquery.jobUser",
      "roles/dataflow.worker",
      "roles/bigquery.metadataViewer",
      "roles/storage.objectViewer",
    ]
  }
}

###############################################################################
#                                   GCS                                       #
###############################################################################

module "bucket-landing" {
  source     = "../../../modules/gcs"
  project_id = module.project-landing.project_id
  prefix     = var.project_ids.landing
  iam = {
    "roles/storage.objectCreator" = ["serviceAccount:${module.landing-default-service-accounts.email}"],
    "roles/storage.admin"         = ["serviceAccount:${module.transformation-default-service-accounts.email}"],
  }

  for_each = var.landing_buckets
  name     = each.value.name
  location = each.value.location
}

module "bucket-transformation" {
  source     = "../../../modules/gcs"
  project_id = module.project-transformation.project_id
  prefix     = var.project_ids.transformation

  for_each = var.transformation_buckets
  name     = each.value.name
  location = each.value.location
  iam = {
    "roles/storage.admin" = ["serviceAccount:${module.transformation-default-service-accounts.email}"],
  }
}

###############################################################################
#                                 Bigquery                                    #
###############################################################################

module "bigquery-datasets-datamart" {
  source     = "../../../modules/bigquery-dataset"
  project_id = module.project-datamart.project_id

  for_each = var.datamart_bq_datasets
  id       = each.value.id
  location = each.value.location
  access   = each.value.access
  access_identities = {
    owner = module.datamart-default-service-accounts.email
  }
  #   access_identities = each.value.access_identities
}

module "bigquery-datasets-dwh" {
  source     = "../../../modules/bigquery-dataset"
  project_id = module.project-dwh.project_id

  for_each = var.dwh_bq_datasets
  id       = each.value.id
  location = each.value.location
  access   = each.value.access
  access_identities = {
    owner  = module.transformation-default-service-accounts.email
    reader = module.dwh-default-service-accounts.email
  }
  #   access_identities = each.value.access_identities
}

###############################################################################
#                                  Network                                    #
###############################################################################
module "vpc-transformation" {
  source     = "../../../modules/net-vpc"
  project_id = module.project-transformation.project_id
  name       = var.transformation_vpc_name
  subnets    = var.transformation_subnets
}

###############################################################################
#                                Pub/Sub                                      #
###############################################################################
module "pubsub-landing" {
  source     = "../../../modules/pubsub"
  project_id = module.project-landing.project_id

  for_each         = local.landing_pubsub
  name             = each.value.name
  subscriptions    = each.value.subscriptions
  subscription_iam = each.value.subscription_iam
}
