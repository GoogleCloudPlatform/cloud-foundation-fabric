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

resource "google_cloud_run_v2_worker_pool" "default_managed" {
  count               = var.type == "WORKERPOOL" && var.managed_revision ? 1 : 0
  provider            = google-beta
  project             = var.project_id
  location            = var.region
  name                = var.name
  labels              = var.labels
  launch_stage        = var.launch_stage
  deletion_protection = var.deletion_protection

  dynamic "scaling" {
    for_each = var.workerpool_config.scaling == null ? [] : [""]
    content {
      scaling_mode          = var.workerpool_config.scaling.mode
      max_instance_count    = var.workerpool_config.scaling.max_instance_count
      min_instance_count    = var.workerpool_config.scaling.min_instance_count
      manual_instance_count = var.workerpool_config.scaling.manual_instance_count
    }
  }

  template {
    labels         = var.revision.labels
    encryption_key = var.encryption_key
    revision       = local.revision_name

    gpu_zonal_redundancy_disabled = var.revision.gpu_zonal_redundancy_disabled
    dynamic "node_selector" {
      for_each = var.revision.node_selector == null ? [] : [""]
      content {
        accelerator = var.revision.node_selector.accelerator
      }
    }
    # Serverless VPC connector is not supported
    # dynamic "vpc_access" {
    #   for_each = local.connector == null ? [] : [""]
    #   content {
    #     connector = local.connector
    #     egress    = try(var.revision.vpc_access.egress, null)
    #   }
    # }
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

resource "google_cloud_run_v2_worker_pool" "default_unmanaged" {
  count               = var.type == "WORKERPOOL" && !var.managed_revision ? 1 : 0
  provider            = google-beta
  project             = var.project_id
  location            = var.region
  name                = var.name
  labels              = var.labels
  launch_stage        = var.launch_stage
  deletion_protection = var.deletion_protection

  dynamic "scaling" {
    for_each = var.workerpool_config.scaling == null ? [] : [""]
    content {
      scaling_mode          = var.workerpool_config.scaling.mode
      max_instance_count    = var.workerpool_config.scaling.max_instance_count
      min_instance_count    = var.workerpool_config.scaling.min_instance_count
      manual_instance_count = var.workerpool_config.scaling.manual_instance_count
    }
  }

  template {
    labels         = var.revision.labels
    encryption_key = var.encryption_key
    revision       = local.revision_name

    gpu_zonal_redundancy_disabled = var.revision.gpu_zonal_redundancy_disabled
    dynamic "node_selector" {
      for_each = var.revision.node_selector == null ? [] : [""]
      content {
        accelerator = var.revision.node_selector.accelerator
      }
    }

    # Serverless VPC connector is not supported
    # dynamic "vpc_access" {
    #   for_each = local.connector == null ? [] : [""]
    #   content {
    #     connector = local.connector
    #     egress    = try(var.revision.vpc_access.egress, null)
    #   }
    # }
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
      template[0].containers,
      template[0].labels
    ]
  }
}

resource "google_cloud_run_v2_worker_pool_iam_binding" "binding" {
  for_each = var.type == "WORKERPOOL" ? var.iam : {}
  project  = local.resource.project
  location = local.resource.location
  name     = local.resource.name
  role     = each.key
  members  = each.value
}
