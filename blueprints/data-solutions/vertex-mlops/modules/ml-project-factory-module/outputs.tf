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

# TODO(): proper outputs


locals {
  docker_split = try(split("/", module.artifact_registry["docker-repo"].id), null)
  docker_repo  = try("${local.docker_split[3]}-docker.pkg.dev/${local.docker_split[1]}/${local.docker_split[5]}", null)
  gh_config = {
    WORKLOAD_ID_PROVIDER = try(google_iam_workload_identity_pool_provider.github_provider[0].name, null)
    SERVICE_ACCOUNT      = try(module.service-accounts["sa-github"].email, null)
    PROJECT_ID           = try(module.project.project_id, null)
    DOCKER_REPO          = local.docker_repo
  }
}

  

output "github" {
 
  description = "Github Configuration"
  value = local.gh_config
}


output "workload_identity_pool_name" {
  description = "Resource name for the Workload Identity Pool."
  value       = [google_iam_workload_identity_pool.github_pool.*.name]
}

output "google_iam_workload_identity_pool_provider" {
  description = "Id for the Workload Identity Pool Provider."
  value       = [google_iam_workload_identity_pool_provider.github_provider.*.name]
}

output "project" {
  description = "The project resource as return by the `project` module"
  value       = module.project

  depends_on = [
    google_compute_subnetwork_iam_member.default,
    module.dns
  ]
}

output "project_id" {
  description = "Project ID."
  value       = module.project.project_id
  depends_on = [
    google_compute_subnetwork_iam_member.default,
    module.dns
  ]
}
