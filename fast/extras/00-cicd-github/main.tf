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
    for k, v in var.repositories : local.repositories[k] if v.has_modules
  ]
  _repository_files = flatten([
    for k, v in var.repositories : [
      for f in concat(
        [for f in fileset(path.module, "${v.populate_from}/*.md") : f],
        [for f in fileset(path.module, "${v.populate_from}/*.tf") : f]
        ) : {
        repository = k
        file       = f
        name       = replace(f, "${v.populate_from}/", "")
      }
    ] if v.populate_from != null
  ])
  modules_ref = var.modules_ref == null ? "" : "?ref=${var.modules_ref}"
  modules_repository = (
    length(local._modules_repository) > 0
    ? local._modules_repository.0
    : null
  )
  repositories = {
    for k, v in var.repositories :
    k => v.create_options == null ? k : github_repository.default[k].name
  }
  repository_files = merge(
    {
      for k in local._repository_files :
      "${k.repository}/${k.name}" => k
      if !endswith(k.name, ".tf") || (
        !startswith(k.name, "0") && k.name != "globals.tf"
      )
    },
    {
      for k, v in var.repositories :
      "${k}/templates/providers.tf.tpl" => {
        repository = k
        file       = "../../assets/templates/providers.tf.tpl"
        name       = "templates/providers.tf.tpl"
      }
      if v.populate_from != null
    }
  )
}

resource "github_repository" "default" {
  for_each = {
    for k, v in var.repositories : k => v if v.create_options != null
  }
  name = each.key
  description = (
    each.value.create_options.description != null
    ? each.value.create_options.description
    : "FAST stage ${each.key}."
  )
  visibility         = each.value.create_options.visibility
  auto_init          = each.value.create_options.auto_init
  allow_auto_merge   = try(each.value.create_options.allow.auto_merge, null)
  allow_merge_commit = try(each.value.create_options.allow.merge_commit, null)
  allow_rebase_merge = try(each.value.create_options.allow.rebase_merge, null)
  allow_squash_merge = try(each.value.create_options.allow.squash_merge, null)
  has_issues         = try(each.value.create_options.features.issues, null)
  has_projects       = try(each.value.create_options.features.projects, null)
  has_wiki           = try(each.value.create_options.features.wiki, null)
  gitignore_template = try(each.value.create_options.templates.gitignore, null)
  license_template   = try(each.value.create_options.templates.license, null)

  dynamic "template" {
    for_each = (
      try(each.value.create_options.templates.repository, null) != null
      ? [""]
      : []
    )
    content {
      owner      = each.value.create_options.templates.repository.owner
      repository = each.value.create_options.templates.repository.name
    }
  }
}

resource "tls_private_key" "default" {
  count     = local.modules_repository != null ? 1 : 0
  algorithm = "ED25519"
}

resource "github_repository_deploy_key" "default" {
  count      = local.modules_repository == null ? 0 : 1
  title      = "Modules repository access"
  repository = local.modules_repository
  key        = tls_private_key.default.0.public_key_openssh
  read_only  = true
}

resource "github_actions_secret" "default" {
  for_each = local.modules_repository == null ? {} : {
    for k, v in local.repositories :
    k => v if k != local.modules_repository
  }
  repository      = each.key
  secret_name     = "CICD_MODULES_KEY"
  plaintext_value = tls_private_key.default.0.private_key_openssh
}

resource "github_repository_file" "default" {
  for_each = (
    local.modules_repository == null ? {} : local.repository_files
  )
  repository = local.repositories[each.value.repository]
  branch     = "main"
  file       = each.value.name
  content = (
    endswith(each.value.name, ".tf") && local.modules_repository != null
    ? replace(
      file(each.value.file),
      "/source\\s*=\\s*\"../../../modules/([^/\"]+)\"/",
      "source = \"git@github.com:${var.organization}/${local.modules_repository}.git//$1${local.modules_ref}\"" # "
    )
    : file(each.value.file)
  )
  commit_message      = "${var.commmit_config.message} (${each.value.name})"
  commit_author       = var.commmit_config.author
  commit_email        = var.commmit_config.email
  overwrite_on_create = true
}
