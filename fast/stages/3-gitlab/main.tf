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

module "project" {
  source          = "../../../modules/project"
  parent          = var.folder_ids.gitlab
  billing_account = var.billing_account.id
  prefix          = var.prefix
  name            = "prod-gitlab-0"
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
    host_project = var.host_project_ids.prod-landing
    # TODO looks like with the current custom role we cannot grant roles at network level
    network_subnet_users = {
      "${var.regions.primary}/landing-gitlab-server-ew1" = ["serviceAccount:${var.service_accounts.gitlab}"]
      "${var.regions.primary}/landing-gitlab-runners-ew1" = ["serviceAccount:${var.service_accounts.gitlab}"]
    }
    service_identity_subnet_iam = {
      "${var.regions.primary}/landing-gitlab-server-ew1" = ["cloudservices","compute"]
      "${var.regions.primary}/landing-gitlab-runners-ew1" = ["cloudservices","compute"]
    }
  }
}


module "squid-proxy-gitlab" {
  source     = "./squid-proxy"
  project_id = module.project.project_id
  region     = var.regions.primary
  network_config = {
    network_self_link      = var.vpc_self_links.prod-landing
    proxy_subnet_self_link = var.subnet_self_links.prod-landing["${var.regions.primary}/landing-gitlab-server-ew1"]
  }
}