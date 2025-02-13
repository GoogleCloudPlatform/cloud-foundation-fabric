/**
 * Copyright 2024 Google LLC
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

module "project" {
  source          = "../../../modules/project"
  parent          = try(var.project_create.parent, null)
  billing_account = try(var.project_create.billing_account_id, null)
  prefix          = var.project_create == null ? null : var.prefix
  name            = var.project_id
  project_create  = var.project_create != null
  services = [
    "compute.googleapis.com",
    "memcache.googleapis.com",
    "redis.googleapis.com",
    "sqladmin.googleapis.com",
    "sql-component.googleapis.com",
    "stackdriver.googleapis.com",
    "dns.googleapis.com",
    "iam.googleapis.com",
  ]
  shared_vpc_service_config = {
    attach       = true
    host_project = var.network_config.host_project
    service_agent_iam = {
      "roles/compute.networkUser" = [
        "cloudservices", "compute"
      ]
    }
    network_users = var.admin_principals
  }
}
