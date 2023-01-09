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

# tfdoc:file:description Project.

locals {
  secret_id          = format("mongodb-server-%s-password", var.cluster_id)
  keyfile_secret_id  = format("mongodb-server-%s-keyfile", var.cluster_id)
  replica_set        = "rs0"
  cluster_name       = format("mongodb-cluster-%s", var.cluster_id)
  private_dns_domain = format("%s.mongodb.internal.", var.cluster_id)
}

module "project" {
  source         = "../../../modules/project"
  name           = var.project_id
  project_create = var.project_create
  services = [
    "compute.googleapis.com",
    "dns.googleapis.com",
    "secretmanager.googleapis.com",
  ]
}
