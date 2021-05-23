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
#                                 Project                                     #
###############################################################################
module "project-id-landing" {
  source         = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/project?ref=v4.2.0"
  name           = var.landing_project_id
  project_create = false
}

###############################################################################
#                                   IAM                                       #
###############################################################################
module "landing-default-service-accounts" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/iam-service-account?ref=v4.2.0"
  project_id = var.landing_project_id

  name = var.landing_service_account

  iam_project_roles = {
    "${var.landing_project_id}" = [
      "roles/pubsub.publisher",
    ]
  }
}

###############################################################################
#                                   GCS                                       #
###############################################################################
module "bucket-landing" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/gcs?ref=v4.2.0"
  project_id = var.landing_project_id
  prefix     = var.landing_project_id
  iam = {
    "roles/storage.objectCreator" = ["serviceAccount:${module.landing-default-service-accounts.email}"],
    "roles/storage.admin"         = ["serviceAccount:${module.transformation-default-service-accounts.email}"],
  }

  for_each = var.landing_buckets

  name     = each.value.name
  location = each.value.location
}

###############################################################################
#                                Pub/Sub                                      #
###############################################################################
module "pubsub-landing" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/pubsub?ref=v4.2.0"
  project_id = var.landing_project_id

  for_each = local.landing_pubsub

  name             = each.value.name
  subscriptions    = each.value.subscriptions
  subscription_iam = each.value.subscription_iam
}
