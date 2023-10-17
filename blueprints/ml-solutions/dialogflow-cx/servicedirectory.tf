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

# tfdoc:file:description Service Directory resources.

resource "google_service_directory_namespace" "namespace" {
  provider     = google-beta
  project      = module.project.project_id
  namespace_id = "${var.prefix}-namespace"
  location     = var.region
}

resource "google_service_directory_service" "service" {
  provider   = google-beta
  service_id = "${var.prefix}-webhook"
  namespace  = google_service_directory_namespace.namespace.id
}

resource "google_service_directory_endpoint" "endpoint" {
  provider    = google-beta
  endpoint_id = "${var.prefix}-endpoint"
  service     = google_service_directory_service.service.id

  metadata = {
    prefix = var.prefix
    region = var.region
  }

  network = "projects/${module.project.number}/locations/global/networks/${regex("([^/]+$)", local.vpc)[0]}"
  address = module.ilb-l7.address
  port    = 443
}
