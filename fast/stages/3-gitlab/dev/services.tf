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

locals {
  gitlab_buckets = [
    "gitlab-artifacts", "gitlab-mr-diffs", "gitlab-lfs", "gitlab-uploads",
    "gitlab-packages", "gitlab-dependency-proxy", "gitlab-terraform-state",
    "gitlab-pages"
  ]
}

module "db" {
  source         = "../../../../modules/cloudsql-instance"
  project_id     = module.project.project_id
  region         = var.region
  name           = "gitlab"
  availability_type = var.gitlab_config.ha_required ? "REGIONAL" : "ZONAL"
  network_config = {
    authorized_networks = {
      gcp  = "10.0.0.0/8"
      home = "192.168.0.0/16"
    }
    connectivity = {
      psa_config = {
        private_network = var.vpc_self_links.dev-spoke-0
      }
    }
  }
  database_version = "POSTGRES_13"
  databases = [
    "gitlabhq_production"
  ]
  tier             = "db-g1-small"
  users            = {
    # generatea password for user1
    gitlab = {
      password = null
      type     = "BUILT_IN"
    }
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

#resource "google_filestore_instance" "nfs" {
#  project = module.project.project_id
#  name     = "gitlab-nfs"
#  location = "${var.region}-b"
#  tier     = "STANDARD"
#
#  file_shares {
#    capacity_gb = 1024
#    name        = "gitlab"
#
#    nfs_export_options {
##      ip_ranges   = [module.gitlab-instance.internal_ip]
#      ip_ranges   = ["10.0.0.0/8"]
#      access_mode = "READ_WRITE"
#      squash_mode = "NO_ROOT_SQUASH"
#    }
#  }
#
#  networks {
#    network      = "gitlab"
#    modes        = ["MODE_IPV4"]
#    connect_mode = "DIRECT_PEERING"
#  }
#}

module "gitlab_object_storage" {
  source        = "../../../../modules/gcs"
  for_each      = toset(local.gitlab_buckets)
  project_id    = module.project.project_id
  prefix        = var.prefix
  name          = each.key
  storage_class = "STANDARD"
  location      = var.region
  iam           = {
    "roles/storage.objectUser" = [
      "serviceAccount:${module.gitlab-sa.email}",
    ]
  }
}