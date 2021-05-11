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
module "project-id-services" {
  source         = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/project?ref=v4.2.0"
  name           = var.services_project_id
  project_create = false
}

###############################################################################
#                                   IAM                                       #
###############################################################################
module "services-default-service-accounts" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/iam-service-account?ref=v4.2.0"
  project_id = var.services_project_id

  name = var.services_service_account

  iam_project_roles = {
    "${var.services_project_id}" = [
      "roles/editor",
    ]
  }
}
