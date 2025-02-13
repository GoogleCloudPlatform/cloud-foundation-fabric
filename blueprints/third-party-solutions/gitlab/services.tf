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


locals {
  gitlab_buckets = [
    "gitlab-artifacts", "gitlab-mr-diffs", "gitlab-lfs", "gitlab-uploads",
    "gitlab-packages", "gitlab-dependency-proxy", "gitlab-terraform-state",
    "gitlab-pages"
  ]
}

#######################################################################
#                     GITLAB MANAGED SERVICES                         #
#######################################################################

# https://docs.gitlab.com/ee/install/requirements.html#database
module "db" {
  source            = "../../../modules/cloudsql-instance"
  project_id        = module.project.project_id
  region            = var.region
  name              = var.cloudsql_config.name
  availability_type = var.gitlab_config.ha_required ? "REGIONAL" : "ZONAL"
  network_config = {
    authorized_networks = {}
    connectivity = {
      psa_configs = [{
        private_network = var.network_config.network_self_link
      }]
    }
  }
  database_version = var.cloudsql_config.database_version
  databases = [
    "gitlabhq_production"
  ]
  tier = var.cloudsql_config.tier
  users = {
    # generate password for user1
    gitlab = {
      password = null
      type     = "BUILT_IN"
    }
  }
}

# https://docs.gitlab.com/ee/install/requirements.html#redis
resource "google_redis_instance" "cache" {
  project            = module.project.project_id
  region             = var.region
  name               = var.redis_config.name
  tier               = var.redis_config.tier
  memory_size_gb     = var.redis_config.memory_size_gb
  authorized_network = var.network_config.network_self_link
  connect_mode       = "PRIVATE_SERVICE_ACCESS"

  redis_version = var.redis_config.version
  display_name  = "Gitlab Redis Instance"
  persistence_config {
    persistence_mode    = var.redis_config.persistence_mode
    rdb_snapshot_period = var.redis_config.rdb_snapshot_period
  }
}

# https://docs.gitlab.com/ee/administration/object_storage.html#google-cloud-storage-gcs
module "gitlab_object_storage" {
  source        = "../../../modules/gcs"
  for_each      = toset(local.gitlab_buckets)
  project_id    = module.project.project_id
  prefix        = var.prefix
  name          = each.key
  storage_class = var.gcs_config.storage_class
  location      = var.gcs_config.location
  versioning    = var.gcs_config.enable_versioning
  iam = {
    "roles/storage.objectUser" = [
      "serviceAccount:${module.gitlab-sa.email}",
    ]
  }
}
