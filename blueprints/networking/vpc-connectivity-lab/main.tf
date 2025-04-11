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

# tfdoc:file:description Project setup.

module "project" {
  source          = "../../../modules/project"
  name            = var.project_id
  parent          = try(var.project_create_config.parent_id, null)
  billing_account = try(var.project_create_config.billing_account_id, null)
  project_reuse = (
    try(var.project_create_config.billing_account_id, null) != null
    ? null
    : {}
  )
  prefix = var.prefix
  services = [
    "compute.googleapis.com",
    "dns.googleapis.com",
    "networkconnectivity.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ]
}
