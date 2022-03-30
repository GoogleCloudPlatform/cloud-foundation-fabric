/**
 * Copyright 2022 Google LLC
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

variable "organization_id" {
  description = "The organization id for the associated services"
}

variable "billing_account" {
  description = "The ID of the billing account to associate this project with"
}

variable "prefix" {
  description = "Customer name to use as prefix for resources' naming"
}

# TODO: support folder instead of a list of projects?
variable "monitored_projects_list" {
  type        = list(string)
  description = "ID of the projects to be monitored (where limits and quotas data will be pulled)"
}

variable "schedule_cron" {
  description = "Cron format schedule to run the Cloud Function. Default is every 5 minutes."
  default     = "*/5 * * * *"
}

variable "project_monitoring_services" {
  description = "Service APIs enabled by default in new projects."
  default = [
    "cloudbilling.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudscheduler.googleapis.com",
    "compute.googleapis.com",
    "cloudfunctions.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "oslogin.googleapis.com",
    "servicenetworking.googleapis.com",
    "serviceusage.googleapis.com",
  ]
}

variable "project_vm_services" {
  description = "Service APIs enabled by default in new projects."
  default = [
    "cloudbilling.googleapis.com",
    "compute.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "servicenetworking.googleapis.com",
  ]
}

variable "region" {
  description = "Region used to deploy subnets"
  default     = "europe-west1"
}

variable "zone" {
  description = "Zone used to deploy vms"
  default     = "europe-west1-b"
}