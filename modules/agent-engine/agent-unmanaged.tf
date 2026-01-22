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

resource "google_vertex_ai_reasoning_engine" "unmanaged" {
  count        = var.managed ? 0 : 1
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
    agent_framework = var.agent_engine_config.agent_framework
    class_methods = (
      length(var.agent_engine_config.class_methods) > 0
      ? jsonencode(var.agent_engine_config.class_methods)
      : null
    )
    service_account = local.service_account_email

    dynamic "deployment_spec" {
      for_each = (
        var.agent_engine_config.container_concurrency != null ||
        var.agent_engine_config.max_instances != null ||
        var.agent_engine_config.min_instances != null ||
        var.agent_engine_config.resource_limits != null ||
        length(var.agent_engine_config.environment_variables) > 0 ||
        length(var.agent_engine_config.secret_environment_variables) > 0
        ? { 1 = 1 }
        : {}
      )

      content {
        container_concurrency = var.agent_engine_config.container_concurrency
        max_instances         = var.agent_engine_config.max_instances
        min_instances         = var.agent_engine_config.min_instances
        resource_limits       = var.agent_engine_config.resource_limits

        dynamic "env" {
          for_each = var.agent_engine_config.environment_variables

          content {
            name  = env.key
            value = env.value
          }
        }

        dynamic "secret_env" {
          for_each = var.agent_engine_config.secret_environment_variables

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

    dynamic "package_spec" {
      for_each = var.deployment_files.package_config == null ? {} : { 1 = 1 }

      content {
        python_version = var.agent_engine_config.python_version
        dependency_files_gcs_uri = (
          var.deployment_files.package_config.are_paths_local
          ? "gs://${local.bucket_name}/${google_storage_bucket_object.dependencies[0].name}"
          : var.deployment_files.package_config.dependencies_path
        )
        requirements_gcs_uri = (
          var.deployment_files.package_config.are_paths_local
          ? "gs://${local.bucket_name}/${google_storage_bucket_object.requirements[0].name}"
          : var.deployment_files.package_config.requirements_path
        )
        pickle_object_gcs_uri = (
          var.deployment_files.package_config.are_paths_local
          ? "gs://${local.bucket_name}/${google_storage_bucket_object.pickle[0].name}"
          : var.deployment_files.package_config.pickle_path
        )
      }
    }

    dynamic "source_code_spec" {
      for_each = var.deployment_files.source_config == null ? {} : { 1 = 1 }

      content {
        inline_source {
          source_archive = filebase64(var.deployment_files.source_config.source_path)
        }

        python_spec {
          entrypoint_module = var.deployment_files.source_config.entrypoint_module
          entrypoint_object = var.deployment_files.source_config.entrypoint_object
          requirements_file = var.deployment_files.source_config.requirements_path
          version           = var.agent_engine_config.python_version
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      spec[0].package_spec,
      spec[0].source_code_spec[0].inline_source[0].source_archive
    ]
  }
}
