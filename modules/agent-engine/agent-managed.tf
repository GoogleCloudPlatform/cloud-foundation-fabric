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

resource "google_vertex_ai_reasoning_engine" "managed" {
  provider     = google-beta
  count        = var.managed ? 1 : 0
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
      var.agent_engine_config.class_methods == null
      ? null
      : var.agent_engine_config.class_methods
    )
    service_account = local.service_account_email

    dynamic "deployment_spec" {
      for_each = (
        var.agent_engine_config.container_concurrency != null ||
        var.agent_engine_config.max_instances != null ||
        var.agent_engine_config.min_instances != null ||
        var.agent_engine_config.resource_limits != null ||
        var.networking_config != null ||
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

        dynamic "psc_interface_config" {
          for_each = var.networking_config == null ? {} : { 1 = 1 }

          content {
            network_attachment = lookup(
              local.ctx.psc_network_attachments,
              var.networking_config.network_attachment_id,
              var.networking_config.network_attachment_id
            )

            dynamic "dns_peering_configs" {
              for_each = var.networking_config.dns_peering_configs

              content {
                domain = dns_peering_configs.key
                target_network = lookup(
                  local.ctx.networks,
                  dns_peering_configs.value.target_network_name,
                  dns_peering_configs.value.target_network_name
                )
                target_project = (
                  dns_peering_configs.value.target_project_id == null
                  ? local.project_id
                  : lookup(
                    local.ctx.project_ids,
                    dns_peering_configs.value.target_project_id,
                    dns_peering_configs.value.target_project_id
                  )
                )
              }
            }
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
      for_each = var.deployment_files.package_config != null ? { 1 = 1 } : {}

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
      for_each = var.deployment_files.source_config != null ? { 1 = 1 } : {}

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

  dynamic "context_spec" {
    for_each = var.memory_bank_config != null ? { 1 = 1 } : {}

    content {
      memory_bank_config {
        disable_memory_revisions = var.memory_bank_config.disable_memory_revisions

        dynamic "generation_config" {
          for_each = (
            var.memory_bank_config.generation_config != null ? { 1 = 1 } : {}
          )
          content {
            model = lookup(
              local.ctx.models,
              var.memory_bank_config.generation_config.model,
              var.memory_bank_config.generation_config.model
            )
          }
        }

        dynamic "similarity_search_config" {
          for_each = (
            var.memory_bank_config.similarity_search_config != null ? { 1 = 1 } : {}
          )
          content {
            embedding_model = lookup(
              local.ctx.models,
              var.memory_bank_config.similarity_search_config.embedding_model,
              var.memory_bank_config.similarity_search_config.embedding_model
            )
          }
        }

        dynamic "ttl_config" {
          for_each = (
            var.memory_bank_config.ttl_config != null ? { 1 = 1 } : {}
          )
          content {
            default_ttl                 = var.memory_bank_config.ttl_config.default_ttl
            memory_revision_default_ttl = var.memory_bank_config.ttl_config.memory_revision_default_ttl

            dynamic "granular_ttl_config" {
              for_each = (
                var.memory_bank_config.ttl_config.granular_ttl_config != null
                ? { 1 = 1 }
                : {}
              )
              content {
                create_ttl = (
                  var.memory_bank_config.ttl_config.granular_ttl_config.create_ttl
                )
                generate_created_ttl = (
                  var.memory_bank_config.ttl_config.granular_ttl_config.generate_created_ttl
                )
                generate_updated_ttl = (
                  var.memory_bank_config.ttl_config.granular_ttl_config.generate_updated_ttl
                )
              }
            }
          }
        }
      }
    }
  }
}
