/**
 * Copyright 2025 Google LLC
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

resource "mongodbatlas_project" "default" {
  name   = var.atlas_config.project_name
  org_id = var.atlas_config.organization_id
}

resource "mongodbatlas_cluster" "default" {
  project_id                  = mongodbatlas_project.default.id
  name                        = var.atlas_config.cluster_name
  provider_name               = "GCP"
  provider_instance_size_name = var.atlas_config.instance_size
  provider_region_name        = var.atlas_config.region
  mongo_db_major_version      = var.atlas_config.database_version
}

resource "mongodbatlas_privatelink_endpoint" "default" {
  project_id    = mongodbatlas_project.default.id
  provider_name = "GCP"
  region        = var.atlas_config.region
}
