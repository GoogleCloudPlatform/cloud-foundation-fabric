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
#                                   IAM                                       #
###############################################################################

module "datamart-sa" {
  source     = "../../../modules/iam-service-account"
  project_id = var.project_ids.datamart
  name       = var.service_account_names.datamart
  iam_project_roles = {
    "${var.project_ids.datamart}" = ["roles/editor"]
  }
}

module "dwh-sa" {
  source     = "../../../modules/iam-service-account"
  project_id = var.project_ids.dwh
  name       = var.service_account_names.dwh
}

module "landing-sa" {
  source     = "../../../modules/iam-service-account"
  project_id = var.project_ids.landing
  name       = var.service_account_names.landing
  iam_project_roles = {
    "${var.project_ids.landing}" = ["roles/pubsub.publisher"]
  }
}

module "services-sa" {
  source     = "../../../modules/iam-service-account"
  project_id = var.project_ids.services
  name       = var.service_account_names.services
  iam_project_roles = {
    "${var.project_ids.services}" = ["roles/editor"]
  }
}

module "transformation-sa" {
  source     = "../../../modules/iam-service-account"
  project_id = var.project_ids.transformation
  name       = var.service_account_names.transformation
  iam_project_roles = {
    "${var.project_ids.transformation}" = [
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

module "landing-buckets" {
  source     = "../../../modules/gcs"
  for_each   = var.landing_buckets
  project_id = var.project_ids.landing
  prefix     = var.project_ids.landing
  name       = each.value.name
  location   = each.value.location
  iam = {
    "roles/storage.objectCreator" = [module.landing-sa.iam_email]
    "roles/storage.admin"         = [module.transformation-sa.iam_email]
  }
  encryption_key = var.service_encryption_key_ids.multiregional
}

module "transformation-buckets" {
  source     = "../../../modules/gcs"
  for_each   = var.transformation_buckets
  project_id = var.project_ids.transformation
  prefix     = var.project_ids.transformation
  name       = each.value.name
  location   = each.value.location
  iam = {
    "roles/storage.admin" = [module.transformation-sa.iam_email]
  }
  encryption_key = var.service_encryption_key_ids.multiregional
}

###############################################################################
#                                 Bigquery                                    #
###############################################################################

module "datamart-bq" {
  source     = "../../../modules/bigquery-dataset"
  for_each   = var.datamart_bq_datasets
  project_id = var.project_ids.datamart
  id         = each.key
  location   = each.value.location
  iam = {
    for k, v in each.value.iam : k => (
      k == "roles/bigquery.dataOwner"
      ? concat(v, [module.datamart-sa.iam_email])
      : v
    )
  }
  encryption_key = var.service_encryption_key_ids.multiregional
}

module "dwh-bq" {
  source     = "../../../modules/bigquery-dataset"
  for_each   = var.dwh_bq_datasets
  project_id = var.project_ids.dwh
  id         = each.key
  location   = each.value.location
  iam = {
    for k, v in each.value.iam : k => (
      k == "roles/bigquery.dataOwner"
      ? concat(v, [module.dwh-sa.iam_email])
      : v
    )
  }
  encryption_key = var.service_encryption_key_ids.multiregional
}

###############################################################################
#                                  Network                                    #
###############################################################################
module "vpc-transformation" {
  source     = "../../../modules/net-vpc"
  project_id = var.project_ids.transformation
  name       = var.transformation_vpc_name
  subnets    = var.transformation_subnets
}

###############################################################################
#                                Pub/Sub                                      #
###############################################################################

module "landing-pubsub" {
  source     = "../../../modules/pubsub"
  for_each   = var.landing_pubsub
  project_id = var.project_ids.landing
  name       = each.key
  subscriptions = {
    for k, v in each.value : k => { labels = v.labels, options = v.options }
  }
  subscription_iam = {
    for k, v in each.value : k => merge(v.iam, {
      "roles/pubsub.subscriber" = [module.transformation-sa.iam_email]
    })
  }
  kms_key = var.service_encryption_key_ids.global
}
