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

locals {
  kms_keys = {
    for k, v in var.kms_keys : k => {
      iam    = coalesce(v.iam, {})
      labels = coalesce(v.labels, {})
      locations = (
        v.locations == null
        ? var.kms_defaults.locations
        : v.locations
      )
      rotation_period = (
        v.rotation_period == null
        ? var.kms_defaults.rotation_period
        : v.rotation_period
      )
    }
  }
  kms_locations = distinct(flatten([
    for k, v in local.kms_keys : v.locations
  ]))
  kms_locations_keys = {
    for loc in local.kms_locations : loc => {
      for k, v in local.kms_keys : k => v if contains(v.locations, loc)
    }
  }
  project_services = [
    "cloudkms.googleapis.com",
    "secretmanager.googleapis.com",
    "stackdriver.googleapis.com"
  ]
  _data_platform_projects = {
    dev = [
      for project in data.google_project.dp-dev-project : project.project_number
    ]
    prod = [
      for project in data.google_project.dp-prod-project : project.project_number
    ]
  }
  _vpc_sc_perimeter_projects = {
    for k in concat(try(keys(var.vpc_sc_perimeter_projects), []), try(keys(var.vpc_sc_dataplatform_projects), [])) :
    k => concat(
      #try(flatten(lookup(var.vpc_sc_perimeter_projects, k, [])), []),
      try(flatten(lookup(var.vpc_sc_dataplatform_projects, k, [])), []),
      try(flatten(lookup(local._data_platform_projects, k, [])), []),
    )
  }
}

data "google_projects" "dp-dev-projects" {
  count  = var.vpc_sc_dataplatform_folders != null ? 1 : 0
  filter = "parent.type:folder parent.id:${var.vpc_sc_dataplatform_folders.dev}"
}

data "google_project" "dp-dev-project" {
  count      = length(try(data.google_projects.dp-dev-projects[0].projects, []))
  project_id = data.google_projects.dp-dev-projects[0].projects[count.index].project_id
}

data "google_projects" "dp-prod-projects" {
  count  = var.vpc_sc_dataplatform_folders != null ? 1 : 0
  filter = "parent.type:folder parent.id:${var.vpc_sc_dataplatform_folders.dev}"
}

data "google_project" "dp-prod-project" {
  count      = length(try(data.google_projects.dp-dev-projects[0].projects, []))
  project_id = data.google_projects.dp-dev-projects[0].projects[count.index].project_id
}

