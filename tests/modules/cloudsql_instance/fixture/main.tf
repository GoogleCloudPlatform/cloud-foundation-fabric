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

module "test" {
  source               = "../../../../modules/cloudsql-instance"
  project_id           = "my-project"
  authorized_networks  = var.authorized_networks
  availability_type    = var.availability_type
  backup_configuration = var.backup_configuration
  database_version     = var.database_version
  databases            = var.databases
  disk_size            = var.disk_size
  disk_type            = var.disk_type
  flags                = var.flags
  labels               = var.labels
  name                 = var.name
  network              = var.network
  prefix               = var.prefix
  region               = var.region
  replicas             = var.replicas
  users                = var.users
  tier                 = var.tier
  deletion_protection  = var.deletion_protection
  ipv4_enabled         = var.ipv4_enabled
}
