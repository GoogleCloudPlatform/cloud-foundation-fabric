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
    for k, v in var.projects : [
      for f in concat(
        [for f in fileset(path.module, "${v.populate_from}/*.svg") : f],
        [for f in fileset(path.module, "${v.populate_from}/*.md") : f],
        (v.populate_samples ? [
          for f in fileset(path.module, "${v.populate_from}/*.sample") : f
        ] : []),
        (v.populate_samples ? [
          for f in fileset(path.module, "${v.populate_from}/data/**/*.*") : f
        ] : []),
        [for f in fileset(path.module, "${v.populate_from}/*.tf") : f],
        [for f in fileset(path.module, "${v.populate_from}/templates/*.tpl") : f],
        [for f in fileset(path.module, "${v.populate_from}/terraform.tfvars") : f]
        ) : {
        project = k
        file    = f
        name    = replace(f, "${v.populate_from}/", "")
      }
    ] if v.populate_from != null
  ])
  modules_files = {
    for f in concat(
      [for f in fileset(path.module, "../../../modules/*/*.svg") : f],
      [for f in fileset(path.module, "../../../modules/*/*.md") : f],
      [for f in fileset(path.module, "../../../modules/*/*.tf") : f],
      [for f in fileset(path.module, "../../../modules/*/*.yaml") : f]
    ) : f => replace(f, "../../../modules/", "")
  }
  modules_ref = (
    try(var.modules_config.source_ref, null) == null
    ? ""
    : "?ref=${var.modules_config.source_ref}"
  )
  modules_project = try(var.modules_config.project_name, null)
  modules_group   = var.modules_config.bootstrap ? gitlab_group.default[var.modules_config.group].path : var.modules_config.group
  module_prefix   = try(var.modules_config.module_prefix, null)
  projects = {
    for k, v in var.projects :
    k => v.create_options == null ? k : gitlab_project.default[k].id
  }
  repository_files = merge(
    {
      for k in local._repository_files :
      "${k.project}/${k.name}" => k
      if !endswith(k.name, ".tf") || (
        !startswith(k.name, "0") && k.name != "globals.tf"
      )
    },
    {
      for k, v in var.projects :
      "${k}/workflows/${v.workflow_file}" => {
        project = k
        file    = "./workflows/${v.workflow_file}"
        name    = ".gitlab-ci.yml"
      }
      if v.workflow_file != null
    }
  )
}

resource "gitlab_group" "default" {
  for_each    = var.groups
  name        = each.value.name
  path        = each.value.path
  description = each.value.description
}

resource "gitlab_project" "modules" {
  count        = try(var.modules_config.bootstrap, false) ? 1 : 0
  name         = var.modules_config.project_name
  description  = "FAST Shared modules"
  namespace_id = gitlab_group.default[var.modules_config.group].id
}

resource "gitlab_repository_file" "modules" {
  for_each       = try(var.modules_config.bootstrap, false) ? local.modules_files : {}
  project        = gitlab_project.modules.0.id
  branch         = "main"
  file_path      = "${var.modules_config.module_prefix}${each.value}"
  content        = endswith(each.key, ".png") || endswith(each.key, ".gif") || endswith(each.key, ".svg") ? filebase64(each.key) : base64encode(file(each.key))
  commit_message = "${var.commit_config.message} (${each.value})"
  author_name    = var.commit_config.author
  author_email   = var.commit_config.email
}

resource "gitlab_project" "default" {
  for_each = {
    for k, v in var.projects : k => v if v.create_options != null
  }
  name = each.key
  description = (
    each.value.create_options.description != null
    ? each.value.create_options.description
    : "FAST stage ${each.key}."
  )
  visibility_level       = each.value.create_options.visibility
  merge_requests_enabled = try(each.value.create_options.features.merge_requests, null)
  namespace_id           = try(gitlab_group.default[each.value.group].id, each.value.group)
  issues_enabled         = try(each.value.create_options.features.issues, null)
  wiki_enabled           = try(each.value.create_options.features.wiki, null)
}

resource "tls_private_key" "default" {
  algorithm = "ED25519"
}

resource "gitlab_deploy_key" "example" {
  count = (
    try(var.modules_config.key_config.create_key, null) == true ? 1 : 0
  )
  project = var.modules_config.bootstrap ? gitlab_project.modules.0.id : "${var.modules_config.namespace}/${var.modules_config.project_name}"
  title   = "Modules repository access"
  key = (
    try(var.modules_config.key_config.keypair_path, null) == null
    ? tls_private_key.default.public_key_openssh
    : file(pathexpand("${var.modules_config.key_config.keypair_path}.pub"))
  )
}

resource "gitlab_project_variable" "default" {
  for_each = (
    try(var.modules_config.key_config.create_secrets, null) == true
    ? local.projects
    : {}
  )
  project = local.projects[each.key]
  key     = "CICD_MODULES_KEY"
  value = (
    try(var.modules_config.key_config.keypair_path, null) == null
    ? tls_private_key.default.private_key_openssh
    : file(pathexpand(var.modules_config.key_config.keypair_path))
  )
  protected = false
}

resource "gitlab_repository_file" "default" {
  for_each  = local.modules_project == null ? {} : local.repository_files
  project   = local.projects[each.value.project]
  branch    = "main"
  file_path = each.value.name
  content = (
    endswith(each.value.name, ".tf") && local.modules_project != null
    ? base64encode(replace(
      file(each.value.file),
      "/source(\\s*)=\\s*\"../../../modules/([^/\"]+)\"/",
      "source$1= \"git::ssh://git@${var.gitlab_config.hostname}:${var.gitlab_config.ssh_port}/${local.modules_group}/${local.modules_project}.git//${local.module_prefix}$2${local.modules_ref}\"" # "
    ))
    : endswith(each.value.name, ".png") || endswith(each.value.name, ".gif") || endswith(each.value.name, ".svg") ? filebase64(each.value.file) : base64encode(file(each.value.file))
  )
  commit_message = "${var.commit_config.message} (${each.value.name})"
  author_name    = var.commit_config.author
  author_email   = var.commit_config.email
}
