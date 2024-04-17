/**
 * Copyright 2024 Google LLC
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
  _repository_files = flatten([
    for k, v in var.repositories : [
      for f in concat(
        [for f in fileset(path.module, "${v.populate_from}/*.svg") : f],
        [for f in fileset(path.module, "${v.populate_from}/*.md") : f],
        (v.populate_samples ? [for f in fileset(path.module, "${v.populate_from}/*.sample") : f] : []),
        (v.populate_samples ? [for f in fileset(path.module, "${v.populate_from}/data/**/*.*") : f] : []),
        [for f in fileset(path.module, "${v.populate_from}/*.tf") : f]
        ) : {
        repository = k
        file       = f
        name       = replace(replace(f, "${v.populate_from}/", ""), (v.populate_samples ? "data/" : ""), (v.populate_samples ? "data.sample/" : ""))
      }
    ] if v.populate_from != null
  ])
  modules_ref = (
    try(var.modules_config.source_ref, null) == null
    ? ""
    : "?ref=${var.modules_config.source_ref}"
  )
  modules_repo  = try(var.modules_config.repository_name, null)
  module_prefix = try(var.modules_config.module_prefix, null)
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
    },
    {
      for k, v in var.repositories :
      "${k}/templates/workflow-github.yaml" => {
        repository = k
        file       = "../../assets/templates/workflow-github.yaml"
        name       = "templates/workflow-github.yaml"
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
  algorithm = "ED25519"
}

resource "github_repository_deploy_key" "default" {
  count = (
    try(var.modules_config.key_config.create_key, null) == true ? 1 : 0
  )
  title = "Modules repository access"
  # if an organization is part of the repo name, we need to strip it
  # as the resource interpolates the provider org
  repository = (
    length(split("/", local.modules_repo)) == 1
    ? local.modules_repo
    : split("/", local.modules_repo)[1]
  )
  key = (
    try(var.modules_config.key_config.keypair_path, null) == null
    ? tls_private_key.default.public_key_openssh
    : file(pathexpand("${var.modules_config.key_config.keypair_path}.pub"))
  )
  read_only = true
}

resource "github_actions_secret" "default" {
  for_each = (
    try(var.modules_config.key_config.create_secrets, null) == true
    ? local.repositories
    : {}
  )
  repository  = each.key
  secret_name = "CICD_MODULES_KEY"
  plaintext_value = (
    try(var.modules_config.key_config.keypair_path, null) == null
    ? tls_private_key.default.private_key_openssh
    : file(pathexpand(var.modules_config.key_config.keypair_path))
  )
}

resource "github_branch" "default" {
  for_each = (
    try(var.pull_request_config.create, null) == true
    ? github_repository.default
    : {}
  )
  repository    = each.key
  branch        = var.pull_request_config.head_ref
  source_branch = var.pull_request_config.base_ref
}

resource "github_repository_file" "default" {
  for_each   = local.modules_repo == null ? {} : local.repository_files
  repository = local.repositories[each.value.repository]
  branch     = var.pull_request_config.create == true ? github_branch.default[each.value.repository].branch : "main"
  file       = each.value.name
  content = (
    endswith(each.value.name, ".tf") && local.modules_repo != null
    ? replace(
      file(each.value.file),
      "/source(\\s*)=\\s*\"../../../modules/([^/\"]+)\"/",
      "source$1= \"git@github.com:${local.modules_repo}.git//${local.module_prefix}$2${local.modules_ref}\"" # "
    )
    : file(each.value.file)
  )
  commit_message      = "${var.commit_config.message} (${each.value.name})"
  commit_author       = var.commit_config.author
  commit_email        = var.commit_config.email
  overwrite_on_create = true
}

resource "github_repository_pull_request" "default" {
  for_each = (
    try(var.pull_request_config.create, null) == true
    ? github_repository.default
    : {}
  )
  base_repository = each.key
  title           = var.pull_request_config.title
  body            = var.pull_request_config.body
  base_ref        = var.pull_request_config.base_ref
  head_ref        = github_branch.default[each.key].branch

  depends_on = [
    github_repository_file.default
  ]
}
