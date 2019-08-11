# Copyright 2019 Google LLC
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

###############################################################################
#                        Terraform top-level resources                        #
###############################################################################

module "project-terraform" {
  # source          = "terraform-google-modules/project-factory/google//modules/fabric-project"
  # version         = "3.0.0"
  source          = "github.com/terraform-google-modules/terraform-google-project-factory//modules/fabric-project?ref=32a539a"
  parent_type     = var.root_type
  parent_id       = var.root_id
  billing_account = var.billing_account_id
  prefix          = var.prefix
  name            = "terraform"
  lien_reason     = "terraform"
  owners          = var.terraform_owners
  activate_apis   = var.project_services
}

module "gcs-terraform" {
  # source        = "terraform-google-modules/cloud-storage/google"
  # version       = "0.1.0"
  source     = "github.com/terraform-google-modules/terraform-google-cloud-storage?ref=3f27f26"
  prefix     = var.prefix
  names      = ["tf-bootstrap"]
  project_id = module.project-terraform.project_id
  location   = var.gcs_location
}
