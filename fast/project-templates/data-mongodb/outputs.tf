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
    id                     = mongodbatlas_cluster.default.cluster_id
    mongo_uri              = mongodbatlas_cluster.default.mongo_uri
    mongo_uri_with_options = mongodbatlas_cluster.default.mongo_uri_with_options
    name                   = mongodbatlas_cluster.default.name
    project_id             = mongodbatlas_cluster.default.project_id
    region                 = mongodbatlas_cluster.default.provider_region_name
    size                   = mongodbatlas_cluster.default.provider_instance_size_name
    srv_address            = mongodbatlas_cluster.default.srv_address
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
