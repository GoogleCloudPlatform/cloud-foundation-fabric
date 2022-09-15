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

locals {
  gitlab_cicd_https = { for k, v in local.cicd_repositories_by_system["gitlab"] : k => v.create ? gitlab_project.projects[k].http_url_to_repo : data.gitlab_project.projects[k].http_url_to_repo }
  gitlab_cicd_ssh   = { for k, v in local.cicd_repositories_by_system["gitlab"] : k => v.create ? gitlab_project.projects[k].ssh_url_to_repo : data.gitlab_project.projects[k].ssh_url_to_repo }
  github_cicd_https = { for k, v in local.cicd_repositories_by_system["github"] : k => v.create ? github_repository.repositories[k].http_clone_url : data.github_repository.repositories[k].http_clone_url }
  github_cicd_ssh   = { for k, v in local.cicd_repositories_by_system["github"] : k => v.create ? github_repository.repositories[k].git_clone_url : data.github_repository.repositories[k].git_clone_url }

  tfvars = {
    cicd_repositories = merge(local.cicd_repositories_by_system["gitlab"], local.cicd_repositories_by_system["github"])
    cicd_ssh_urls     = merge(local.gitlab_cicd_ssh, local.github_cicd_ssh)
    cicd_https_urls   = merge(local.gitlab_cicd_https, local.github_cicd_https)
  }
}

output "tfvars" {
  description = "Terraform variable files for the following stages."
  sensitive   = true
  value       = local.tfvars
}
