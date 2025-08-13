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

resource "google_cloud_run_v2_service" "service" {
  count                = var.type == "SERVICE" && var.managed_revision ? 1 : 0
  provider             = google-beta
  project              = var.project_id
  location             = var.region
  name                 = var.name
  ingress              = var.service_config.ingress
  invoker_iam_disabled = var.service_config.invoker_iam_disabled
  labels               = var.labels
  launch_stage         = var.launch_stage
  custom_audiences     = var.service_config.custom_audiences
  deletion_protection  = var.deletion_protection
  iap_enabled          = var.service_config.iap_config != null

  template {
    labels         = var.revision.labels
    encryption_key = var.encryption_key
    revision       = local.revision_name
    execution_environment = (
      var.service_config.gen2_execution_environment
      ? "EXECUTION_ENVIRONMENT_GEN2" : "EXECUTION_ENVIRONMENT_GEN1"
    )
    gpu_zonal_redundancy_disabled    = var.revision.gpu_zonal_redundancy_disabled
    max_instance_request_concurrency = var.service_config.max_concurrency
    dynamic "node_selector" {
      for_each = var.revision.node_selector == null ? [] : [""]
      content {
        accelerator = var.revision.node_selector.accelerator
      }
    }
    dynamic "scaling" {
      for_each = var.service_config.scaling == null ? [] : [""]
      content {
        max_instance_count = var.service_config.scaling.max_instance_count
        min_instance_count = var.service_config.scaling.min_instance_count
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
      for_each = var.revision.vpc_access.subnet == null && var.revision.vpc_access.network == null ? [] : [""]
      content {
        egress = var.revision.vpc_access.egress
        network_interfaces {
          subnetwork = var.revision.vpc_access.subnet
          network    = var.revision.vpc_access.network
          tags       = var.revision.vpc_access.tags
        }
      }
    }
    timeout         = var.service_config.timeout
    service_account = local.service_account_email
    dynamic "containers" {
      for_each = var.containers
      content {
        name       = containers.key
        image      = containers.value.image
        depends_on = containers.value.depends_on
        command    = containers.value.command
        args       = containers.value.args
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
          for_each = { for k, v in coalesce(containers.value.volume_mounts, tomap({})) : k => v if k != "cloudsql" }
          content {
            name       = volume_mounts.key
            mount_path = volume_mounts.value
          }
        }
        # CloudSQL is the last mount in the list returned by API
        dynamic "volume_mounts" {
          for_each = { for k, v in coalesce(containers.value.volume_mounts, tomap({})) : k => v if k == "cloudsql" }
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
                port = containers.value.liveness_probe.http_get.port
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
                port = containers.value.startup_probe.http_get.port
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
      for_each = { for k, v in var.volumes : k => v if v.cloud_sql_instances == null }
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

        dynamic "empty_dir" {
          for_each = volumes.value.empty_dir_size == null ? [] : [""]
          content {
            medium     = "MEMORY"
            size_limit = volumes.value.empty_dir_size
          }
        }
        dynamic "gcs" {
          for_each = volumes.value.gcs == null ? [] : [""]
          content {
            bucket    = volumes.value.gcs.bucket
            read_only = volumes.value.gcs.is_read_only
          }
        }
        dynamic "nfs" {
          for_each = volumes.value.nfs == null ? [] : [""]
          content {
            server    = volumes.value.nfs.server
            path      = volumes.value.nfs.path
            read_only = volumes.value.nfs.is_read_only
          }
        }
      }
    }
    # CloudSQL is the last volume in the list returned by API
    dynamic "volumes" {
      for_each = { for k, v in var.volumes : k => v if v.cloud_sql_instances != null }
      content {
        name = volumes.key
        dynamic "cloud_sql_instance" {
          for_each = length(coalesce(volumes.value.cloud_sql_instances, [])) == 0 ? [] : [""]
          content {
            instances = volumes.value.cloud_sql_instances
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      client,
      client_version,
      template[0].annotations["run.googleapis.com/operation-id"],
    ]
  }
}

resource "google_cloud_run_v2_service" "service_unmanaged" {
  count                = var.type == "SERVICE" && !var.managed_revision ? 1 : 0
  provider             = google-beta
  project              = var.project_id
  location             = var.region
  name                 = var.name
  ingress              = var.service_config.ingress
  invoker_iam_disabled = var.service_config.invoker_iam_disabled
  labels               = var.labels
  launch_stage         = var.launch_stage
  custom_audiences     = var.service_config.custom_audiences
  deletion_protection  = var.deletion_protection
  iap_enabled          = var.service_config.iap_config != null

  template {
    labels         = var.revision.labels
    encryption_key = var.encryption_key
    revision       = local.revision_name
    execution_environment = (
      var.service_config.gen2_execution_environment
      ? "EXECUTION_ENVIRONMENT_GEN2" : "EXECUTION_ENVIRONMENT_GEN1"
    )
    gpu_zonal_redundancy_disabled    = var.revision.gpu_zonal_redundancy_disabled
    max_instance_request_concurrency = var.service_config.max_concurrency
    dynamic "node_selector" {
      for_each = var.revision.node_selector == null ? [] : [""]
      content {
        accelerator = var.revision.node_selector.accelerator
      }
    }
    dynamic "scaling" {
      for_each = var.service_config.scaling == null ? [] : [""]
      content {
        max_instance_count = var.service_config.scaling.max_instance_count
        min_instance_count = var.service_config.scaling.min_instance_count
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
      for_each = var.revision.vpc_access.subnet == null && var.revision.vpc_access.network == null ? [] : [""]
      content {
        egress = var.revision.vpc_access.egress
        network_interfaces {
          subnetwork = var.revision.vpc_access.subnet
          network    = var.revision.vpc_access.network
          tags       = var.revision.vpc_access.tags
        }
      }
    }
    timeout         = var.service_config.timeout
    service_account = local.service_account_email
    dynamic "containers" {
      for_each = var.containers
      content {
        name       = containers.key
        image      = containers.value.image
        depends_on = containers.value.depends_on
        command    = containers.value.command
        args       = containers.value.args
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
          for_each = { for k, v in coalesce(containers.value.volume_mounts, tomap({})) : k => v if k != "cloudsql" }
          content {
            name       = volume_mounts.key
            mount_path = volume_mounts.value
          }
        }
        # CloudSQL is the last mount in the list returned by API
        dynamic "volume_mounts" {
          for_each = { for k, v in coalesce(containers.value.volume_mounts, tomap({})) : k => v if k == "cloudsql" }
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
                port = containers.value.liveness_probe.http_get.port
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
                port = containers.value.startup_probe.http_get.port
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
      for_each = { for k, v in var.volumes : k => v if v.cloud_sql_instances == null }
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

        dynamic "empty_dir" {
          for_each = volumes.value.empty_dir_size == null ? [] : [""]
          content {
            medium     = "MEMORY"
            size_limit = volumes.value.empty_dir_size
          }
        }
        dynamic "gcs" {
          for_each = volumes.value.gcs == null ? [] : [""]
          content {
            bucket    = volumes.value.gcs.bucket
            read_only = volumes.value.gcs.is_read_only
          }
        }
        dynamic "nfs" {
          for_each = volumes.value.nfs == null ? [] : [""]
          content {
            server    = volumes.value.nfs.server
            path      = volumes.value.nfs.path
            read_only = volumes.value.nfs.is_read_only
          }
        }
      }
    }
    # CloudSQL is the last volume in the list returned by API
    dynamic "volumes" {
      for_each = { for k, v in var.volumes : k => v if v.cloud_sql_instances != null }
      content {
        name = volumes.key
        dynamic "cloud_sql_instance" {
          for_each = length(coalesce(volumes.value.cloud_sql_instances, [])) == 0 ? [] : [""]
          content {
            instances = volumes.value.cloud_sql_instances
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      build_config,
      client,
      client_version,
      template[0].annotations["run.googleapis.com/operation-id"],
      template[0].containers,
      template[0].labels
    ]
  }
}

resource "google_cloud_run_v2_service_iam_binding" "binding" {
  for_each = var.type == "SERVICE" ? var.iam : {}
  project  = local.resource.project
  location = local.resource.location
  name     = local.resource.name
  role     = each.key
  members  = each.value
}

resource "google_iap_web_cloud_run_service_iam_member" "member" {
  for_each               = var.service_config.iap_config == null ? toset([]) : toset(var.service_config.iap_config.iam_additive)
  project                = local.resource.project
  location               = local.resource.location
  cloud_run_service_name = local.resource.name
  role                   = "roles/iap.httpsResourceAccessor"
  member                 = each.key
}

resource "google_iap_web_cloud_run_service_iam_binding" "binding" {
  for_each = (
    var.service_config.iap_config == null ? {}
    : length(var.service_config.iap_config.iam) == 0 ? {} : { 1 = 1 }
  )
  project                = local.resource.project
  location               = local.resource.location
  cloud_run_service_name = local.resource.name
  role                   = "roles/iap.httpsResourceAccessor"
  members                = var.service_config.iap_config.iam
}
