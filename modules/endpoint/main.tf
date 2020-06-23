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
  iam_roles_bindings = {
    for k in var.iam_roles : k => lookup(var.iam_members, k, [])
  }
}

resource "google_endpoints_service" "default" {
  project              = var.project_id
  service_name         = var.service_name

  openapi_config       = var.openapi_config != null ? file(var.openapi_config) : null
  grpc_config          = var.grpc_config != null ? file(var.grpc_config) : null

  protoc_output_base64 = var.protoc_output_base64 != null ? base64encode(file(var.protoc_output_base64)) : null
}

resource "google_project_service" "default" {
  project                    = var.project_id
  service                    = google_endpoints_service.default.service_name
  disable_on_destroy         = true
  disable_dependent_services = true
}

resource "google_endpoints_service_iam_binding" "default" {
  for_each     = local.iam_roles_bindings

  service_name = google_endpoints_service.default.service_name
  role         = "roles/${each.key}"
  members      = each.value
}
