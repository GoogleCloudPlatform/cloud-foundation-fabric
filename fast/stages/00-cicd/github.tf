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
  github_groups = distinct([for k, v in local.cicd_repositories_by_system["github"] : v.group])
}

provider "github" {
  base_url = var.github.url
  owner    = length(local.github_groups) > 0 ? local.github_groups[0] : null
}

data "github_organization" "organization" {
  for_each = toset(local.github_groups)
  name     = each.value
}

data "github_repository" "repositories" {
  for_each  = { for name, repo in local.cicd_repositories_by_system["github"] : name => repo if !try(repo.create, true) }
  full_name = format("%s/%s", each.value.group, each.value.name)
}

resource "github_repository" "repositories" {
  for_each = { for name, repo in local.cicd_repositories_by_system["github"] : name => repo if try(repo.create, true) }

  name        = each.value.name
  description = each.value.description

  visibility = var.github.visibility
  
  archive_on_destroy = false
}

resource "github_actions_secret" "actions-modules-key" {
  for_each = { for name, repo in local.cicd_repositories_by_system["github"] : name => repo }

  repository      = try(each.value.create, true) ? github_repository.repositories[each.key].name : data.github_repository.repositories[each.key].name
  secret_name     = "CICD_MODULES_KEY"
  plaintext_value = tls_private_key.cicd-modules-key.private_key_openssh
}
