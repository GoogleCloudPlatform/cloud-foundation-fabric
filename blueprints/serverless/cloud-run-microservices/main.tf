/**
 * Copyright 2024 Google LLC
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

# tfdoc:file:description Project resources.

locals {
  cloud_run_domain = "run.app."
  svc_a_name       = "svc-a"
  svc_b_name       = "svc-b"
  two_projects = (
    try(var.project_configs.service.project_id, null) != null ? true : false
  )
}

module "main-project" {
  source          = "../../../modules/project"
  name            = var.project_configs.main.project_id
  prefix          = var.prefix
  project_create  = var.project_configs.main.billing_account_id != null
  billing_account = try(var.project_configs.main.billing_account_id, null)
  parent          = try(var.project_configs.main.parent, null)
  # Enable Shared VPC by default, a use case will use this project as host
  shared_vpc_host_config = {
    enabled = true
  }
  services = [
    "run.googleapis.com",
    "compute.googleapis.com",
    "dns.googleapis.com",
    "vpcaccess.googleapis.com"
  ]
}

module "service-project" {
  source          = "../../../modules/project"
  count           = local.two_projects == true ? 1 : 0
  name            = var.project_configs.service.project_id
  prefix          = var.prefix
  project_create  = var.project_configs.service.billing_account_id != null
  billing_account = try(var.project_configs.service.billing_account_id, null)
  parent          = try(var.project_configs.service.parent, null)
  shared_vpc_service_config = {
    host_project = module.main-project.project_id
  }
  services = [
    "compute.googleapis.com",
    "run.googleapis.com",
  ]
}
