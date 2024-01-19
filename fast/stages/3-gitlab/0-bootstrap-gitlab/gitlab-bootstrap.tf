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

locals {
  network_repo_files = fileset("${path.module}/../../2-networking-a-peering", "*")
  bootstrap_repo_files = fileset("${path.module}/../../0-bootstrap", "*")

}

resource "gitlab_group" "admins" {
  name        = "admins"
  path        = "admins"
  description = "Org Admins group"
}

#######################################################################
#                        BOOTSTRAP PROJECT                            #
#######################################################################

# Create a project in the example group
resource "gitlab_project" "bootstrap" {
  name         = "bootstrap"
  description  = "GCP Organization Bootstrap"
  namespace_id = gitlab_group.admins.id
}

resource "gitlab_repository_file" "bootstrap_repo" {
  for_each       = toset(fileset("${path.module}/../../0-bootstrap", "*"))
  project        = gitlab_project.bootstrap.id
  file_path      = each.key
  branch         = "main"
  content        = endswith(each.key, ".png") || endswith(each.key, ".gif") ? filebase64("${path.module}/../../0-bootstrap/${each.key}") : base64encode(file("${path.module}/../../0-bootstrap/${each.key}"))
  author_email   = "terraform@${var.gitlab_hostname}"
  author_name    = "Terraform"
  commit_message = "bootstrap: add ${each.key} file"
}

resource "gitlab_repository_file" "bootstrap_ci" {
  project        = gitlab_project.bootstrap.id
  file_path      = ".gitlab-ci.yml"
  branch         = "main"
  content        = base64encode(file("${path.module}/workflows/bootstrap-workflow.yaml"))
  author_email   = "terraform@${var.gitlab_hostname}"
  author_name    = "Terraform"
  commit_message = "bootstrap: add ci file"
}

#######################################################################
#                          RESMAN PROJECT                             #
#######################################################################

# Create a project in the example group
resource "gitlab_project" "resman" {
  name         = "resman"
  description  = "GCP Resource Management"
  namespace_id = gitlab_group.admins.id
}

resource "gitlab_repository_file" "resman_repo" {
  for_each       = toset(fileset("${path.module}/../../1-resman", "*"))
  project        = gitlab_project.resman.id
  file_path      = each.key
  branch         = "main"
  content        = endswith(each.key, ".png") || endswith(each.key, ".gif") ? filebase64("${path.module}/../../1-resman/${each.key}") : base64encode(file("${path.module}/../../1-resman/${each.key}"))
  author_email   = "terraform@${var.gitlab_hostname}"
  author_name    = "Terraform"
  commit_message = "bootstrap: add ${each.key} file"
}

resource "gitlab_repository_file" "resman_ci" {
  project        = gitlab_project.resman.id
  file_path      = ".gitlab-ci.yml"
  branch         = "main"
  content        = base64encode(file("${path.module}/workflows/resman-workflow.yaml"))
  author_email   = "terraform@${var.gitlab_hostname}"
  author_name    = "Terraform"
  commit_message = "bootstrap: add ci file"
}

#######################################################################
#                         NETWORK PROJECT                             #
#######################################################################

resource "gitlab_group" "network" {
  name        = "network"
  path        = "network"
  description = "Networking Group"
}

# Create a project in the example group
resource "gitlab_project" "network" {
  name         = "network"
  description  = "Networking"
  namespace_id = gitlab_group.network.id
}

resource "gitlab_repository_file" "network_repo" {
  for_each       = toset(local.network_repo_files)
  project        = gitlab_project.network.id
  file_path      = each.key
  branch         = "main"
  content        = endswith(each.key, ".png") ? filebase64("${path.module}/../../2-networking-a-peering/${each.key}") : base64encode(file("${path.module}/../../2-networking-a-peering/${each.key}"))
  author_email   = "terraform@${var.gitlab_hostname}"
  author_name    = "Terraform"
  commit_message = "bootstrap: add ${each.key} file"
}

resource "gitlab_repository_file" "network_ci" {
  project        = gitlab_project.network.id
  file_path      = ".gitlab-ci.yml"
  branch         = "main"
  content        = base64encode(file("${path.module}/workflows/networking-workflow.yaml"))
  author_email   = "terraform@${var.gitlab_hostname}"
  author_name    = "Terraform"
  commit_message = "bootstrap: add ci file"
}