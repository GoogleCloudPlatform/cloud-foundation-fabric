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

module "project" {
  source          = "../../../modules/project"
  name            = var.project_id
  parent          = try(var.project_create.parent, null)
  billing_account = try(var.project_create.billing_account_id, null)
  project_create  = var.project_create != null
  prefix          = var.project_create == null ? null : var.prefix
  services = [
    "servicenetworking.googleapis.com",
  ]
}

module "vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.project.project_id
  name       = "vpc"
  psa_config = {
    ranges = { cloud-sql = var.cloudsql_psa_range }
    routes = null
  }
}

module "db" {
  source           = "../../../modules/cloudsql-instance"
  project_id       = module.project.project_id
  network          = module.vpc.self_link
  name             = "db"
  region           = var.regions.primary
  database_version = "POSTGRES_13"
  tier             = var.tier

  replicas = {
    for name, region in var.regions :
    name => region
    if name != "primary"
  }
}
