/**
 * Copyright 2026 Google LLC
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
  agent_gateways = {
    for k, v in var.networking_config.agent_gateways :
    k => v == null ? null : lookup(local.ctx.agent_gateways, v, v)
  }
  bucket_name = (
    var.deployment_config.package_config != null && var.bucket_config.create
    ? google_storage_bucket.default[0].name
    : coalesce(var.bucket_config.name, var.name)
  )
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local._ctx_p}${k}:${kk}" => vv
    } if !endswith(k, "_vars")
  }
  has_deployment_spec = (
    var.agent_runtime_config.container_concurrency != null ||
    var.agent_runtime_config.max_instances != null ||
    var.agent_runtime_config.min_instances != null ||
    var.agent_runtime_config.resource_limits != null ||
    local.agent_gateways.egress != null ||
    local.agent_gateways.ingress != null ||
    local.network_attachment_id != null ||
    length(var.agent_runtime_config.environment_variables) > 0 ||
    length(var.agent_runtime_config.secret_environment_variables) > 0
  )
  location = lookup(
    local.ctx.locations, var.region, var.region
  )
  network_attachment_id = (
    var.networking_config.network_attachment_id == null
    ? null
    : lookup(
      local.ctx.psc_network_attachments,
      var.networking_config.network_attachment_id,
      var.networking_config.network_attachment_id
    )
  )
  project_id = lookup(
    local.ctx.project_ids, var.project_id, var.project_id
  )
  resource = {
    id     = local._resource.id
    object = local._resource
  }
}

resource "google_storage_bucket" "default" {
  count = (
    var.bucket_config.create
    && var.deployment_config.package_config != null
    ? 1 : 0
  )
  name                        = coalesce(var.bucket_config.name, var.name)
  project                     = local.project_id
  location                    = local.location
  uniform_bucket_level_access = var.bucket_config.uniform_bucket_level_access
  force_destroy               = !var.enable_deletion_protection
}

resource "google_storage_bucket_object" "dependencies" {
  count = (
    var.deployment_config.package_config != null
    && var.deployment_config.package_config.are_paths_local ? 1 : 0
  )
  name   = "dependencies.tar.gz"
  bucket = local.bucket_name
  source = try(var.deployment_config.package_config.dependencies_path, null)
  source_md5hash = (
    try(var.deployment_config.package_config.dependencies_path, null) == null
    ? null
    : filemd5(var.deployment_config.package_config.dependencies_path)
  )
}

resource "google_storage_bucket_object" "pickle" {
  count = (
    var.deployment_config.package_config != null
    && var.deployment_config.package_config.are_paths_local ? 1 : 0
  )
  name   = "pickle.pkl"
  bucket = local.bucket_name
  source = try(var.deployment_config.package_config.pickle_path, null)
  source_md5hash = (
    try(var.deployment_config.package_config.pickle_path, null) == null
    ? null
    : filemd5(var.deployment_config.package_config.pickle_path)
  )
}

resource "google_storage_bucket_object" "requirements" {
  count = (
    var.deployment_config.package_config != null
    && var.deployment_config.package_config.are_paths_local ? 1 : 0
  )
  name   = "requirements.txt"
  bucket = local.bucket_name
  source = try(var.deployment_config.package_config.requirements_path, null)
  source_md5hash = (
    try(var.deployment_config.package_config.requirements_path, null) == null
    ? null
    : filemd5(var.deployment_config.package_config.requirements_path)
  )
}
