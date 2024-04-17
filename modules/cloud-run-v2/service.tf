/**
 * Copyright 2023 Google LLC
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

resource "google_cloud_run_v2_service" "service" {
  count        = var.create_job ? 0 : 1
  provider     = google-beta
  project      = var.project_id
  location     = var.region
  name         = "${local.prefix}${var.name}"
  ingress      = var.ingress
  labels       = var.labels
  launch_stage = var.launch_stage

  template {
    encryption_key = var.encryption_key
    revision       = local.revision_name
    execution_environment = (
      var.revision.gen2_execution_environment == true
      ? "EXECUTION_ENVIRONMENT_GEN2" : "EXECUTION_ENVIRONMENT_GEN1"
    )
    max_instance_request_concurrency = var.revision.max_concurrency
    dynamic "scaling" {
      for_each = (var.revision.max_instance_count == null && var.revision.min_instance_count == null) ? [] : [""]
      content {
        max_instance_count = var.revision.max_instance_count
        min_instance_count = var.revision.min_instance_count
      }
    }
    dynamic "vpc_access" {
      for_each = local.connector == null ? [] : [""]
      content {
        connector = local.connector
        egress    = try(var.revision.vpc_access.egress, null)
      }
    }
    dynamic "vpc_access" {
      for_each = try(var.revision.vpc_access.subnet, null) == null ? [] : [""]
      content {
        egress = var.revision.vpc_access.egress
        network_interfaces {
          subnetwork = var.revision.vpc_access.subnet
          tags       = var.revision.vpc_access.tags
        }
      }
    }
    timeout         = var.revision.timeout
    service_account = local.service_account_email
    dynamic "containers" {
      for_each = var.containers
      content {
        name    = containers.key
        image   = containers.value.image
        command = containers.value.command
        args    = containers.value.args
        dynamic "env" {
          for_each = coalesce(containers.value.env, tomap({}))
          content {
            name  = env.key
            value = env.value
          }
        }
        dynamic "env" {
          for_each = coalesce(containers.value.env_from_key, tomap({}))
          content {
            name = env.key
            value_source {
              secret_key_ref {
                secret  = env.value.secret
                version = env.value.version
              }
            }
          }
        }
        dynamic "resources" {
          for_each = containers.value.resources == null ? [] : [""]
          content {
            limits            = containers.value.resources.limits
            cpu_idle          = containers.value.resources.cpu_idle
            startup_cpu_boost = containers.value.resources.startup_cpu_boost
          }
        }
        dynamic "ports" {
          for_each = coalesce(containers.value.ports, tomap({}))
          content {
            container_port = ports.value.container_port
            name           = ports.value.name
          }
        }
        dynamic "volume_mounts" {
          for_each = coalesce(containers.value.volume_mounts, tomap({}))
          content {
            name       = volume_mounts.key
            mount_path = volume_mounts.value
          }
        }
        dynamic "liveness_probe" {
          for_each = containers.value.liveness_probe == null ? [] : [""]
          content {
            initial_delay_seconds = containers.value.liveness_probe.initial_delay_seconds
            timeout_seconds       = containers.value.liveness_probe.timeout_seconds
            period_seconds        = containers.value.liveness_probe.period_seconds
            failure_threshold     = containers.value.liveness_probe.failure_threshold
            dynamic "http_get" {
              for_each = containers.value.liveness_probe.http_get == null ? [] : [""]
              content {
                path = containers.value.liveness_probe.http_get.path
                dynamic "http_headers" {
                  for_each = coalesce(containers.value.liveness_probe.http_get.http_headers, tomap({}))
                  content {
                    name  = http_headers.key
                    value = http_headers.value
                  }
                }
              }
            }
            dynamic "grpc" {
              for_each = containers.value.liveness_probe.grpc == null ? [] : [""]
              content {
                port    = containers.value.liveness_probe.grpc.port
                service = containers.value.liveness_probe.grpc.service
              }
            }
          }
        }
        dynamic "startup_probe" {
          for_each = containers.value.startup_probe == null ? [] : [""]
          content {
            initial_delay_seconds = containers.value.startup_probe.initial_delay_seconds
            timeout_seconds       = containers.value.startup_probe.timeout_seconds
            period_seconds        = containers.value.startup_probe.period_seconds
            failure_threshold     = containers.value.startup_probe.failure_threshold
            dynamic "http_get" {
              for_each = containers.value.startup_probe.http_get == null ? [] : [""]
              content {
                path = containers.value.startup_probe.http_get.path
                dynamic "http_headers" {
                  for_each = coalesce(containers.value.startup_probe.http_get.http_headers, tomap({}))
                  content {
                    name  = http_headers.key
                    value = http_headers.value
                  }
                }
              }
            }
            dynamic "tcp_socket" {
              for_each = containers.value.startup_probe.tcp_socket == null ? [] : [""]
              content {
                port = containers.value.startup_probe.tcp_socket.port
              }
            }
            dynamic "grpc" {
              for_each = containers.value.startup_probe.grpc == null ? [] : [""]
              content {
                port    = containers.value.startup_probe.grpc.port
                service = containers.value.startup_probe.grpc.service
              }
            }
          }
        }
      }
    }
    dynamic "volumes" {
      for_each = var.volumes
      content {
        name = volumes.key
        dynamic "secret" {
          for_each = volumes.value.secret == null ? [] : [""]
          content {
            secret       = volumes.value.secret.name
            default_mode = volumes.value.secret.default_mode
            dynamic "items" {
              for_each = volumes.value.secret.path == null ? [] : [""]
              content {
                path    = volumes.value.secret.path
                version = volumes.value.secret.version
                mode    = volumes.value.secret.mode
              }
            }
          }
        }
        dynamic "cloud_sql_instance" {
          for_each = length(coalesce(volumes.value.cloud_sql_instances, [])) == 0 ? [] : [""]
          content {
            instances = volumes.value.cloud_sql_instances
          }
        }
        dynamic "empty_dir" {
          for_each = volumes.value.empty_dir_size == null ? [] : [""]
          content {
            medium     = "MEMORY"
            size_limit = volumes.value.empty_dir_size
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].annotations["run.googleapis.com/operation-id"],
    ]
  }
}

resource "google_cloud_run_v2_service_iam_binding" "binding" {
  for_each = var.create_job ? {} : var.iam
  project  = google_cloud_run_v2_service.service[0].project
  location = google_cloud_run_v2_service.service[0].location
  name     = google_cloud_run_v2_service.service[0].name
  role     = each.key
  members = (
    each.key != "roles/run.invoker" || !local.trigger_sa_create
    ? each.value
    # if invoker role is present and we create trigger sa, add it as member
    : concat(
      each.value, ["serviceAccount:${local.trigger_sa_email}"]
    )
  )
}

