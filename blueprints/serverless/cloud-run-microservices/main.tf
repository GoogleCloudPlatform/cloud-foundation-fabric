/**
 * Copyright 2023 Google LLC
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
  repo             = "repo"
  svc_a_image      = <<EOT
${var.region}-docker.pkg.dev/${var.prj_main_id}/${local.repo}/vpc-network-tester:v1.0
  EOT
  svc_a_name       = "svc-a"
  svc_b_name       = "svc-b"
}

# Main (or host) project
module "project_main" {
  source          = "../../../modules/project"
  name            = var.prj_main_id
  project_create  = var.prj_main_create != null
  billing_account = try(var.prj_main_create.billing_account_id, null)
  parent          = try(var.prj_main_create.parent, null)
  # Enable Shared VPC by default, some use cases will use this project as host
  shared_vpc_host_config = {
    enabled = true
  }
  services = [
    "run.googleapis.com",
    "compute.googleapis.com",
    "dns.googleapis.com",
    "vpcaccess.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com"
  ]
  skip_delete = true
}

# Service project 1
module "project_svc1" {
  source          = "../../../modules/project"
  count           = var.prj_svc1_id != null ? 1 : 0
  name            = var.prj_svc1_id
  project_create  = var.prj_svc1_create != null
  billing_account = try(var.prj_svc1_create.billing_account_id, null)
  parent          = try(var.prj_svc1_create.parent, null)
  shared_vpc_service_config = {
    host_project = module.project_main.project_id
  }
  services = [
    "compute.googleapis.com",
    "run.googleapis.com",
  ]
  skip_delete = true
}
