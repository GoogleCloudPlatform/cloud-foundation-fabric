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
  _service_account_external_email = (
    var.service_account_config.email == null
    ? null
    : lookup(
      local.ctx.iam_principals,
      var.service_account_config.email,
      var.service_account_config.email
    )
  )
  bucket_name = (
    var.bucket_config.create
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
  service_account_email = (
    var.service_account_config.create
    ? google_service_account.default[0].email
    : local._service_account_external_email
  )
  service_account_roles = [
    for role in var.service_account_config.roles
    : lookup(var.context.custom_roles, role, role)
  ]
}

resource "google_vertex_ai_reasoning_engine" "default" {
  display_name = var.name
  project      = local.project_id
  description  = var.description
  region       = local.location

  dynamic "encryption_spec" {
    for_each = var.encryption_key == null ? {} : { 1 = 1 }

    content {
      kms_key_name = lookup(
        local.ctx.kms_keys,
        var.encryption_key,
        var.encryption_key
      )
    }
  }

  spec {
    agent_framework = var.agent_framework
    class_methods = (
      length(var.class_methods) > 0
      ? jsonencode(var.class_methods)
      : null
    )
    service_account = local.service_account_email

    dynamic "deployment_spec" {
      for_each = (
        # length(var.container_spec) > 0 ||
        length(var.environment_variables) > 0 ||
        length(var.secret_environment_variables) > 0
        ? { 1 = 1 }
        : {}
      )

      content {
        dynamic "env" {
          for_each = var.environment_variables

          content {
            name  = env.key
            value = env.value
          }
        }

        dynamic "secret_env" {
          for_each = var.secret_environment_variables

          content {
            name = secret_env.key

            secret_ref {
              secret  = secret_env.value.secret_id
              version = secret_env.value.version
            }
          }
        }
      }
    }

    package_spec {
      python_version           = var.python_version
      dependency_files_gcs_uri = "gs://${local.bucket_name}/${google_storage_bucket_object.dependencies.name}"
      requirements_gcs_uri     = "gs://${local.bucket_name}/${google_storage_bucket_object.requirements.name}"
      pickle_object_gcs_uri = (
        var.generate_pickle
        ? "gs://${local.bucket_name}/${google_storage_bucket_object.pickle_from_src[0].name}"
        : "gs://${local.bucket_name}/${google_storage_bucket_object.pickle[0].name}"
      )
    }
  }
}

# Eventual consistency issue.
# AE doesn't retry (yet) the deployment if bindings are still not active.
resource "time_sleep" "wait_5_minutes" {
  create_duration = "5m"

  depends_on = [
    google_project_iam_member.default
  ]
}

resource "google_storage_bucket" "default" {
  count                       = var.bucket_config.create ? 1 : 0
  name                        = coalesce(var.bucket_config.name, var.name)
  project                     = local.project_id
  location                    = local.location
  uniform_bucket_level_access = var.bucket_config.uniform_bucket_level_access
  force_destroy               = !var.bucket_config.deletion_protection
}

resource "null_resource" "default" {
  count = var.generate_pickle ? 1 : 0

  provisioner "local-exec" {
    command = join(" ", [
      "python",
      "./tools/serialize_agent.py",
      "${var.source_files.path}/${var.source_files.pickle_src}",
      "--output-file ${var.source_files.path}/${var.source_files.pickle_out}",
      "--variable-name ${var.source_files.pickle_src_var_name}"
    ])
  }
}

resource "google_storage_bucket_object" "dependencies" {
  name   = "${filesha1("${var.source_files.path}/${var.source_files.dependencies}")}.tar.gz"
  bucket = local.bucket_name
  source = "${var.source_files.path}/${var.source_files.dependencies}"
}

resource "google_storage_bucket_object" "pickle_from_src" {
  count  = var.generate_pickle ? 1 : 0
  name   = "${filesha1("${var.source_files.path}/${var.source_files.pickle_src}")}.pkl"
  bucket = local.bucket_name
  source = "${var.source_files.path}/${var.source_files.pickle_out}"

  depends_on = [
    null_resource.default
  ]
}

resource "google_storage_bucket_object" "pickle" {
  count  = var.generate_pickle ? 0 : 1
  name   = "${filesha1("${var.source_files.path}/${var.source_files.pickle_out}")}.pkl"
  bucket = local.bucket_name
  source = "${var.source_files.path}/${var.source_files.pickle_out}"
}

resource "google_storage_bucket_object" "requirements" {
  name   = "${filesha1("${var.source_files.path}/${var.source_files.requirements}")}.txt"
  bucket = local.bucket_name
  source = "${var.source_files.path}/${var.source_files.requirements}"
}

resource "google_service_account" "default" {
  count        = var.service_account_config.create ? 1 : 0
  account_id   = coalesce(var.service_account_config.name, var.name)
  project      = local.project_id
  display_name = "Agent Engine ${coalesce(var.service_account_config.name, var.name)}."
}

resource "google_project_iam_member" "default" {
  for_each = (
    var.service_account_config.create
    ? toset(local.service_account_roles)
    : toset([])
  )
  role    = each.key
  project = local.project_id
  member  = google_service_account.default[0].member
}
