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

# https://docs.gitlab.com/ee/install/requirements.html#database

module "db" {
  source     = "../../../../modules/cloudsql-instance"
  project_id = module.project.project_id
  region     = var.region
  name       = "gitlab-0"
  network    = var.vpc_self_links.dev-spoke-0
  allocated_ip_ranges = {
    primary = "cloudsql"
  }
  authorized_networks = {
    gcp  = "10.0.0.0/8"
    home = "192.168.0.0/16"
  }
  database_version = "POSTGRES_13"
  tier             = "db-g1-small"
  # TODO: create gitlab's own admin-level user
  users = {
    sqlserver = null
  }
}

resource "google_redis_instance" "cache" {
  project            = module.project.project_id
  region             = var.region
  name               = "gitlab-0"
  tier               = "BASIC"
  memory_size_gb     = 1
  authorized_network = var.vpc_self_links.dev-spoke-0
  connect_mode       = "PRIVATE_SERVICE_ACCESS"

  redis_version = "REDIS_6_X"
  display_name  = "Terraform Test Instance"
  persistence_config {
    persistence_mode    = "RDB"
    rdb_snapshot_period = "TWELVE_HOURS"
  }
}
