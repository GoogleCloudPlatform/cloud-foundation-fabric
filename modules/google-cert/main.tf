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

locals {
  domains    = var.domains
  name       = var.name
  project_id = var.project_id != null ? var.project_id : data.google_client_config.current[0].project
}

data "google_client_config" "current" {
  count = var.project_id == null ? 1 : 0
}

resource "google_compute_global_address" "address" {
  name    = local.name
  project = local.project_id
}

resource "google_compute_managed_ssl_certificate" "cert" {
  provider = google-beta

  managed { domains = local.domains }
  name    = local.name
  project = local.project_id
}
