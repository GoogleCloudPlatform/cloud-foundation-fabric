# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

##########################
# project-creation
##########################
module "transformation-project-creation" {
  source          = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/project?ref=v4.2.0"
  billing_account = var.billing_account
  parent          = var.parent

  name = join(
    "-",
    [
      var.transformation_project_name,
      var.projects_suffix != null ? var.projects_suffix : random_id.suffix.hex
    ]
  )
  auto_create_network = false
  services = [
    "cloudbuild.googleapis.com",
    "compute.googleapis.com",
    "dataflow.googleapis.com",
    "servicenetworking.googleapis.com",
    "storage-component.googleapis.com",
  ]

  iam_additive = {}
}

##########################
# IAM
##########################
module "set-tf-data-admin-service-account-on-transformation" {
  source = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/project?ref=v4.2.0"

  name           = module.transformation-project-creation.project_id
  project_create = false

  iam = {
    "roles/editor" = [
      "serviceAccount:${module.master-service-account.email}"
    ]
  }

  depends_on = [
    module.master-service-account,
  ]
}
