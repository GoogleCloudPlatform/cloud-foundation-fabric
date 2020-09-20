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
  application_title = var.application_title
  client_name       = var.client_name
  create_client     = var.create_client
  project_id        = var.project_id != null ? var.project_id : data.google_client_config.current[0].project
  support_email     = var.support_email
}

data "google_client_config" "current" {
  count = var.project_id == null ? 1 : 0
}

resource "google_iap_brand" "brand" {
  application_title = local.application_title
  project           = local.project_id  
  support_email     = local.support_email
}

resource "google_iap_client" "client" {
  count        = local.create_client ? 1 : 0

  display_name = local.client_name
  brand        = google_iap_brand.brand.name
}
