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

output "atlas_cluster" {
  description = "MongoDB Atlas cluster."
  value = {
    id          = mongodbatlas_advanced_cluster.default.cluster_id
    mongo_uri   = mongodbatlas_advanced_cluster.default.connection_strings.standard
    name        = mongodbatlas_advanced_cluster.default.name
    project_id  = mongodbatlas_advanced_cluster.default.project_id
    region      = local._cluster_region_config.region_name
    size        = local._cluster_region_config.electable_specs.instance_size
    srv_address = mongodbatlas_advanced_cluster.default.connection_strings.standard_srv
  }
}

output "atlas_project" {
  description = "MongoDB Atlas project."
  value = {
    id     = mongodbatlas_project.default.id
    name   = mongodbatlas_project.default.name
    org_id = mongodbatlas_project.default.org_id
  }
}

output "endpoints" {
  description = "MongoDB Atlas PSC endpoint IP address."
  value       = mongodbatlas_privatelink_endpoint_service.default.private_endpoint_ip_address
}
