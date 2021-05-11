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
#                                 Project                                     #
###############################################################################
module "project-id-transformation" {
  source         = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/project?ref=v4.2.0"
  name           = var.transformation_project_id
  project_create = false
}

###############################################################################
#                                   IAM                                       #
###############################################################################
module "transformation-default-service-accounts" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/iam-service-account?ref=v4.2.0"
  project_id = var.transformation_project_id

  name = var.transformation_service_account

  iam_project_roles = {
    "${var.transformation_project_id}" = [
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
#                                  Network                                    #
###############################################################################
module "vpc-transformation" {
  source = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpc?ref=v4.2.0"

  project_id = var.transformation_project_id
  name       = var.transformation_vpc_name
  subnets    = var.transformation_subnets
}

###############################################################################
#                                    GCS                                      #
###############################################################################
module "bucket-transformation" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/gcs?ref=v4.2.0"
  project_id = var.transformation_project_id
  prefix     = var.transformation_project_id

  for_each = var.transformation_buckets

  name     = each.value.name
  location = each.value.location
  iam = {
    "roles/storage.admin" = ["serviceAccount:${module.transformation-default-service-accounts.email}"],
  }
}
