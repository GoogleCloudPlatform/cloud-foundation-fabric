# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# TODO: shall we use our own modules for testing?

locals {
  prefix = "${var.prefix}-${var.timestamp}-${var.suffix}"
}

module "folder" {
  source = "../../../modules/folder"
  parent = var.parent
  name   = "E2E Tests ${var.timestamp}-${var.suffix}"
}


module "project" {
  source          = "../../../modules/project"
  billing_account = var.billing_account
  name            = "prj"
  parent          = module.folder.id
  prefix          = local.prefix
  services        = local.services
}

module "bucket" {
  source        = "../../../modules/gcs"
  name          = "bucket"
  prefix        = local.prefix
  project_id    = module.project.id
  force_destroy = true
}


module "vpc" {
  source     = "../../../modules/net-vpc"
  name       = "e2e-test"
  project_id = module.project.id
  subnets = [
    {
      ip_cidr_range = "10.0.16.0/24"
      name          = "e2e-test-1"
      region        = var.region
    }
  ]
}


resource "local_file" "terraform_tfvars" {
  filename = "e2e_tests.tfvars"
  content = templatefile("e2e_tests.tfvars.tftpl", {
    bucket             = module.bucket.name
    billing_account_id = var.billing_account
    organization_id    = var.organization_id
    folder_id          = module.folder.id
    prefix             = local.prefix
    project_id         = module.project.id
    region             = var.region
    service_account = {
      id        = "{service_account.id}"
      email     = "{service_account.email}"
      iam_email = "{service_account.iam_email}"
    }
    subnet = module.vpc.subnets["${var.region}/e2e-test-1"]
    vpc    = module.vpc
  })
}

locals {
  services = [
    # trimmed down list of services, to be extended as needed
    "cloudbuild.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "run.googleapis.com",
    "serviceusage.googleapis.com",
    "stackdriver.googleapis.com",
    "storage-component.googleapis.com",
    "storage.googleapis.com",
  ]
}