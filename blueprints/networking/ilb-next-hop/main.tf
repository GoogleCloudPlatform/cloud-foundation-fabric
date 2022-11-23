/**
 * Copyright 2022 Google LLC
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
  addresses = {
    for k, v in module.addresses.internal_addresses :
    trimprefix(k, "${var.prefix}-") => v.address
  }
  zones = { for z in var.zones : z => "${var.region}-${z}" }
}

module "project" {
  source         = "../../../modules/project"
  name           = var.project_id
  project_create = var.project_create
  services = [
    "compute.googleapis.com",
    "dns.googleapis.com",
  ]
}

module "service-accounts" {
  source     = "../../../modules/iam-service-account"
  project_id = module.project.project_id
  name       = "${var.prefix}-gce-vm"
  iam_project_roles = {
    (var.project_id) = [
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
    ]
  }
}

module "addresses" {
  source     = "../../../modules/net-address"
  project_id = module.project.project_id
  internal_addresses = {
    "${var.prefix}-ilb-left" = {
      region     = var.region,
      subnetwork = values(module.vpc-left.subnet_self_links)[0]
    },
    "${var.prefix}-ilb-right" = {
      region     = var.region,
      subnetwork = values(module.vpc-right.subnet_self_links)[0]
    }
  }
}
