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
    connection_strings = (
      mongodbatlas_advanced_cluster.default.connection_strings
    )
    id         = mongodbatlas_advanced_cluster.default.cluster_id
    name       = mongodbatlas_advanced_cluster.default.name
    project_id = mongodbatlas_advanced_cluster.default.project_id
    region     = local.cluster_region_config.region_name
    size       = local.cluster_region_config.electable_specs.instance_size
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
  description = "MongoDB Atlas endpoints."
  value = sort([
    for v in mongodbatlas_privatelink_endpoint_service.default.endpoints :
    v.ip_address
  ])
}
