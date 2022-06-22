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
  gitlab_create_groups   = distinct([for k, v in local.cicd_repositories_by_system["gitlab"] : v.group if try(v.create_group, false)])
  gitlab_existing_groups = distinct([for k, v in local.cicd_repositories_by_system["gitlab"] : v.group if !try(v.create_group, false)])
}

provider "gitlab" {
  base_url = var.gitlab.url
}

data "gitlab_group" "group" {
  for_each  = toset(local.gitlab_existing_groups)
  full_path = each.value
}

data "gitlab_project" "projects" {
  for_each = { for name, repo in local.cicd_repositories_by_system["gitlab"] : name => repo if !try(repo.create, true) }
  id       = format("%s/%s", each.value.group, each.value.name)
}

resource "gitlab_group" "group" {
  for_each = toset(local.gitlab_create_groups)

  name        = each.value
  path        = each.value
  description = "Cloud Foundation Fabric FAST: github.com/GoogleCloudPlatform/cloud-foundation-fabric/tree/master/fast/"
}

resource "gitlab_project" "projects" {
  for_each = { for name, repo in local.cicd_repositories_by_system["gitlab"] : name => repo if try(repo.create, true) }

  name         = each.value.name
  namespace_id = each.value.create_group ? gitlab_group.group[each.value.group].id : data.gitlab_group.group[each.value.group].id
  description  = each.value.description

  visibility_level       = var.gitlab.project_visibility
  shared_runners_enabled = var.gitlab.shared_runners_enabled
  auto_devops_enabled    = false
}

resource "gitlab_project_variable" "project-modules-key" {
  for_each = { for name, repo in local.cicd_repositories_by_system["gitlab"] : name => repo }

  project = try(each.value.create, true) ? gitlab_project.projects[each.key].id : data.gitlab_project.projects[each.key].id

  key   = "CICD_MODULES_KEY"
  value = base64encode(tls_private_key.cicd-modules-key.private_key_openssh)

  protected     = false
  masked        = true
  variable_type = "env_var"
}



