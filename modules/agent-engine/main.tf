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

locals {
  _ctx_p = "$"
  _resource = (
    var.managed
    ? try(google_vertex_ai_reasoning_engine.managed[0], null)
    : try(google_vertex_ai_reasoning_engine.unmanaged[0], null)
  )
  bucket_name = (
    var.deployment_files.package_config != null && var.bucket_config.create
    ? google_storage_bucket.default[0].name
    : coalesce(var.bucket_config.name, var.name)
  )
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local._ctx_p}${k}:${kk}" => vv
    } if k != "condition_vars"
  }
  location = lookup(
    local.ctx.locations, var.region, var.region
  )
  project_id = lookup(
    local.ctx.project_ids, var.project_id, var.project_id
  )
  resource = {
    id     = local._resource.id
    object = local._resource
  }
}

# TODO: fix once eventual consistency issue is solved.
# AE doesn't retry the deployment (yet) if bindings are still not active.
resource "time_sleep" "wait_5_minutes" {
  create_duration = "5m"

  depends_on = [
    google_project_iam_member.default
  ]
}

resource "google_storage_bucket" "default" {
  count = (
    var.bucket_config.create
    && var.deployment_files.package_config != null
    ? 1 : 0
  )
  name                        = coalesce(var.bucket_config.name, var.name)
  project                     = local.project_id
  location                    = local.location
  uniform_bucket_level_access = var.bucket_config.uniform_bucket_level_access
  force_destroy               = !var.bucket_config.deletion_protection
}

resource "google_storage_bucket_object" "dependencies" {
  count = (
    var.deployment_files.package_config != null
    && var.deployment_files.package_config.are_paths_local ? 1 : 0
  )
  name   = "dependencies.tar.gz"
  bucket = local.bucket_name
  source = try(var.deployment_files.package_config.dependencies_path, null)
  source_md5hash = filemd5(
    try(var.deployment_files.package_config.dependencies_path, null)
  )
}

resource "google_storage_bucket_object" "pickle" {
  count = (
    var.deployment_files.package_config != null
    && var.deployment_files.package_config.are_paths_local ? 1 : 0
  )
  name   = "pickle.pkl"
  bucket = local.bucket_name
  source = try(var.deployment_files.package_config.pickle_path, null)
  source_md5hash = filemd5(
    try(var.deployment_files.package_config.pickle_path)
  )
}

resource "google_storage_bucket_object" "requirements" {
  count = (
    var.deployment_files.package_config != null
    && var.deployment_files.package_config.are_paths_local ? 1 : 0
  )
  name   = "requirements.txt"
  bucket = local.bucket_name
  source = try(var.deployment_files.package_config.requirements_path, null)
  source_md5hash = filemd5(
    try(var.deployment_files.package_config.requirements_path)
  )
}
