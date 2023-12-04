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

locals {
  connector = (
    var.vpc_connector_create != null
    ? google_vpc_access_connector.connector.0.id
    : var.revision_annotations.vpcaccess_connector
  )
  egress = {
    all-traffic         = "ALL_TRAFFIC"
    private-ranges-only = "PRIVATE_RANGES_ONLY"
  }
  ingress = {
    all                               = "INGRESS_TRAFFIC_ALL"
    internal                          = "INGRESS_TRAFFIC_INTERNAL_ONLY"
    internal-and-cloud-load-balancing = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  }
  prefix = var.prefix == null ? "" : "${var.prefix}-"
  revision_name = (
    var.revision_name == null ? null : "${var.name}-${var.revision_name}"
  )
  service_account_email = (
    var.service_account_create
    ? (
      length(google_service_account.service_account) > 0
      ? google_service_account.service_account[0].email
      : null
    )
    : var.service_account
  )
  trigger_sa_create = try(
    var.eventarc_triggers.service_account_create, false
  )
  trigger_sa_email = try(
    google_service_account.trigger_service_account[0].email, null
  )
}

resource "google_vpc_access_connector" "connector" {
  count   = var.vpc_connector_create != null ? 1 : 0
  project = var.project_id
  name = (
    var.vpc_connector_create.name != null
    ? var.vpc_connector_create.name
    : var.name
  )
  region         = var.region
  ip_cidr_range  = var.vpc_connector_create.ip_cidr_range
  network        = var.vpc_connector_create.vpc_self_link
  machine_type   = var.vpc_connector_create.machine_type
  max_instances  = var.vpc_connector_create.instances.max
  max_throughput = var.vpc_connector_create.throughput.max
  min_instances  = var.vpc_connector_create.instances.min
  min_throughput = var.vpc_connector_create.throughput.min
  subnet {
    name       = var.vpc_connector_create.subnet.name
    project_id = var.vpc_connector_create.subnet.project_id
  }
}

resource "google_cloud_run_v2_service" "service" {
  project      = var.project_id
  location     = var.region
  name         = "${local.prefix}${var.name}"
  ingress      = try(local.ingress[var.ingress_settings], null)
  launch_stage = var.launch_stage

  template {
    revision = local.revision_name
    scaling {
      max_instance_count = try(
        var.revision_annotations.autoscaling.max_scale, null
      )
      min_instance_count = try(
        var.revision_annotations.autoscaling.min_scale, null
      )
    }
    dynamic "vpc_access" {
      for_each = local.connector != null ? [""] : []
      content {
        connector = local.connector
        egress = (
          try(local.egress[var.revision_annotations.vpcaccess_egress], null)
        )
      }
    }
    dynamic "vpc_access" {
      for_each = var.revision_annotations.network_interfaces != null ? [""] : []
      content {
        egress = var.revision_annotations.vpcaccess_egress
        network_interfaces {
          subnetwork = var.revision_annotations.network_interfaces.subnetwork
          tags       = var.revision_annotations.network_interfaces.tags
        }
      }
    }
    timeout         = var.timeout_seconds
    service_account = local.service_account_email
    dynamic "containers" {
      for_each = var.containers
      content {
        name    = containers.key
        image   = containers.value.image
        command = containers.value.command
        args    = containers.value.args
        dynamic "env" {
          for_each = containers.value.env
          content {
            name  = env.key
            value = env.value
          }
        }
        dynamic "env" {
          for_each = containers.value.env_from_key
          content {
            name = env.key
            value_source {
              secret_key_ref {
                version = env.value.key
                secret  = env.value.name
              }
            }
          }
        }
        dynamic "resources" {
          for_each = containers.value.resources == null ? [] : [""]
          content {
            limits            = resources.value.limits
            cpu_idle          = resources.value.cpu_idle
            startup_cpu_boost = var.startup_cpu_boost
          }
        }
        dynamic "ports" {
          for_each = containers.value.ports
          content {
            container_port = ports.value.container_port
            name           = ports.value.name
          }
        }
        dynamic "volume_mounts" {
          for_each = containers.value.volume_mounts
          content {
            name       = volume_mounts.key
            mount_path = volume_mounts.value
          }
        }

        dynamic "liveness_probe" {
          for_each = containers.value.liveness_probe == null ? [] : [""]
          content {
            initial_delay_seconds = liveness_probe.value.initial_delay_seconds
            timeout_seconds       = liveness_probe.value.timeout_seconds
            period_seconds        = liveness_probe.value.period_seconds
            failure_threshold     = liveness_probe.value.failure_threshold
            dynamic "http_get" {
              for_each = liveness_probe.value.action.http_get == null ? [] : [""]
              content {
                path = http_get.value.path
                dynamic "http_headers" {
                  for_each = http_get.value.http_headers
                  content {
                    name  = http_headers.key
                    value = http_headers.value
                  }
                }
              }
            }
            dynamic "grpc" {
              for_each = liveness_probe.value.action.grpc == null ? [] : [""]
              content {
                port    = grpc.value.port
                service = grpc.value.service
              }
            }
          }
        }
        dynamic "startup_probe" {
          for_each = containers.value.startup_probe == null ? [] : [""]
          content {
            initial_delay_seconds = startup_probe.value.initial_delay_seconds
            timeout_seconds       = startup_probe.value.timeout_seconds
            period_seconds        = startup_probe.value.period_seconds
            failure_threshold     = startup_probe.value.failure_threshold
            dynamic "http_get" {
              for_each = startup_probe.value.action.http_get == null ? [] : [""]
              content {
                path = http_get.value.path
                dynamic "http_headers" {
                  for_each = http_get.value.http_headers
                  content {
                    name  = http_headers.key
                    value = http_headers.value
                  }
                }
              }
            }
            dynamic "tcp_socket" {
              for_each = startup_probe.value.action.tcp_socket == null ? [] : [""]
              content {
                port = tcp_socket.value.port
              }
            }
            dynamic "grpc" {
              for_each = startup_probe.value.action.grpc == null ? [] : [""]
              content {
                port    = grpc.value.port
                service = grpc.value.service
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
        secret {
          secret       = volumes.value.secret_name
          default_mode = volumes.value.default_mode
          dynamic "items" {
            for_each = volumes.value.items
            content {
              path    = items.value.path
              version = items.key
              mode    = items.value.mode
            }
          }
        }
        cloud_sql_instance {
          instances = revision_annotations.cloudsql_instances
        }
      }
    }
    execution_environment = (
      var.gen2_execution_environment == true
      ? "EXECUTION_ENVIRONMENT_GEN2" : "EXECUTION_ENVIRONMENT_GEN1"
    )
    max_instance_request_concurrency = var.container_concurrency
  }
  labels = var.labels
  dynamic "traffic" {
    for_each = var.traffic
    content {
      percent = traffic.value.percent
      type = (
        traffic.value.latest == true
        ? "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
        : "TRAFFIC_TARGET_ALLOCATION_TYPE_REVISION"
      )
      revision = (
        traffic.value.latest == true
        ? null : "${var.name}-${traffic.key}"
      )
      tag = traffic.value.tag
    }
  }

  lifecycle {
    ignore_changes = [
      template.0.annotations["run.googleapis.com/operation-id"],
    ]
  }
}

resource "google_cloud_run_service_iam_binding" "binding" {
  for_each = var.iam
  project  = google_cloud_run_v2_service.service.project
  location = google_cloud_run_v2_service.service.location
  service  = google_cloud_run_v2_service.service.name
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

resource "google_cloud_run_service_iam_member" "default" {
  # if authoritative invoker role is not present and we create trigger sa
  # use additive binding to grant it the role
  count = (
    lookup(var.iam, "roles/run.invoker", null) == null &&
    local.trigger_sa_create
  ) ? 1 : 0
  project  = google_cloud_run_v2_service.service.project
  location = google_cloud_run_v2_service.service.location
  service  = google_cloud_run_v2_service.service.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${local.trigger_sa_email}"
}

resource "google_service_account" "service_account" {
  count        = var.service_account_create ? 1 : 0
  project      = var.project_id
  account_id   = "tf-cr-${var.name}"
  display_name = "Terraform Cloud Run ${var.name}."
}

resource "google_eventarc_trigger" "audit_log_triggers" {
  for_each = var.eventarc_triggers.audit_log
  name     = "${local.prefix}audit-log-${each.key}"
  location = google_cloud_run_v2_service.service.location
  project  = google_cloud_run_v2_service.service.project
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.audit.log.v1.written"
  }
  matching_criteria {
    attribute = "serviceName"
    value     = each.value.service
  }
  matching_criteria {
    attribute = "methodName"
    value     = each.value.method
  }
  destination {
    cloud_run_service {
      service = google_cloud_run_v2_service.service.name
      region  = google_cloud_run_v2_service.service.location
    }
  }
  service_account = local.trigger_sa_email
}

resource "google_eventarc_trigger" "pubsub_triggers" {
  for_each = var.eventarc_triggers.pubsub
  name     = "${local.prefix}pubsub-${each.key}"
  location = google_cloud_run_v2_service.service.location
  project  = google_cloud_run_v2_service.service.project
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.pubsub.topic.v1.messagePublished"
  }
  transport {
    pubsub {
      topic = each.value
    }
  }
  destination {
    cloud_run_service {
      service = google_cloud_run_v2_service.service.name
      region  = google_cloud_run_v2_service.service.location
    }
  }
  service_account = local.trigger_sa_email
}

resource "google_service_account" "trigger_service_account" {
  count        = local.trigger_sa_create ? 1 : 0
  project      = var.project_id
  account_id   = "tf-cr-trigger-${var.name}"
  display_name = "Terraform trigger for Cloud Run ${var.name}."
}
