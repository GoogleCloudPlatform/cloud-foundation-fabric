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
  _modules_repository = [
    for k, v in var.repositories : k if v.modules_source
  ]
  _populate_md = flatten([
    for k, v in var.repositories : [
      for f in fileset(path.module, "${v.populate_with}/*.md") : {
        repository = k
        file       = f
        name       = replace(f, "${v.populate_with}/", "")
      }
    ] if v.populate_with != null
  ])
  _populate_tf = flatten([
    for k, v in var.repositories : [
      for f in fileset(path.module, "${v.populate_with}/*.tf") : {
        repository = k
        file       = f
        name       = replace(f, "${v.populate_with}/", "")
      }
    ] if v.populate_with != null
  ])
  modules_repository = (
    length(local._modules_repository) > 0 ? local._modules_repository.0 : null
  )
  repository_files = {
    for k in concat(
      local._populate_md,
      [
        for f in local._populate_tf :
        f if !startswith(f.name, "0") && f.name != "globals.tf"
      ]
    ) : "${k.repository}/${k.name}" => k
  }
}

resource "github_repository" "default" {
  for_each = var.repositories
  name     = each.key
  description = (
    each.value.description != null
    ? each.value.description
    : "FAST stage ${each.key}."
  )
  visibility         = each.value.visibility
  auto_init          = each.value.auto_init
  allow_auto_merge   = try(each.value.allow.auto_merge, null)
  allow_merge_commit = try(each.value.allow.merge_commit, null)
  allow_rebase_merge = try(each.value.allow.rebase_merge, null)
  allow_squash_merge = try(each.value.allow.squash_merge, null)
  has_issues         = try(each.value.features.issues, null)
  has_projects       = try(each.value.features.projects, null)
  has_wiki           = try(each.value.features.wiki, null)
  gitignore_template = try(each.value.templates.gitignore, null)
  license_template   = try(each.value.templates.license, null)

  dynamic "template" {
    for_each = try(each.value.templates.repository, null) != null ? [""] : []
    content {
      owner      = each.value.templates.repository.owner
      repository = each.value.templates.repository.name
    }
  }
}

resource "tls_private_key" "default" {
  count     = local.modules_repository != null ? 1 : 0
  algorithm = "ED25519"
}

resource "github_actions_secret" "default" {
  count           = local.modules_repository != null ? 1 : 0
  repository      = github_repository.default[local.modules_repository].name
  secret_name     = "CICD_MODULES_KEY"
  plaintext_value = tls_private_key.default.0.private_key_openssh
}

resource "github_repository_file" "default" {
  for_each   = local.repository_files
  repository = github_repository.default[each.value.repository].name
  branch     = "main"
  file       = each.value.name
  content = (
    endswith(each.value.name, ".tf") && local.modules_repository != null
    ? replace(
      file(each.value.file),
      "/source\\s*=\\s*\"../../../",
      "source = \"git@github.com:${var.organization}/${local.modules_repository}.git/"
    )
    : file(each.value.file)
  )
  commit_message      = "${var.commmit_config.message} (${each.value.name})"
  commit_author       = var.commmit_config.author
  commit_email        = var.commmit_config.email
  overwrite_on_create = true
}
