# Copyright 2023 Google LLC
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

# tfdoc:file:description Enables GCP APIs required for executing Terraform.

# Used for retrieving the google provider project id.
# This is the project which will execute the Terraform.
data "google_project" "project" {}

resource "google_project_service" "service" {
  for_each = toset([
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "cloudbilling.googleapis.com",
    "pubsub.googleapis.com"
  ])

  service = each.key

  project            = data.google_project.project.id
  disable_on_destroy = false
}
