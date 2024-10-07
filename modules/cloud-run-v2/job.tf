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

resource "google_cloud_run_v2_job" "job" {
  count               = var.create_job ? 1 : 0
  provider            = google-beta
  project             = var.project_id
  location            = var.region
  name                = "${local.prefix}${var.name}"
  labels              = var.labels
  launch_stage        = var.launch_stage
  deletion_protection = var.deletion_protection
  template {
    task_count = var.revision.job.task_count
    template {
      encryption_key = var.encryption_key
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
      max_retries     = var.revision.job.max_retries
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
              limits = containers.value.resources.limits
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
  }

  lifecycle {
    ignore_changes = [
      template[0].annotations["run.googleapis.com/operation-id"],
    ]
  }
}

resource "google_cloud_run_v2_job_iam_binding" "binding" {
  for_each = var.create_job ? var.iam : {}
  project  = google_cloud_run_v2_job.job[0].project
  location = google_cloud_run_v2_job.job[0].location
  name     = google_cloud_run_v2_job.job[0].name
  role     = each.key
  members  = each.value
}

