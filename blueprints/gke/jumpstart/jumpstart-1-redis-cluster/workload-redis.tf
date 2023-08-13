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
  wl_image = (
    var.create_config.remote_registry == true
    ? "${module.registry.0.image_path}/${var.workload_config.image}"
    : var.workload_config.image
  )
  wl_nodes = flatten([
    for s in data.kubernetes_endpoints_v1.cluster_nodes.subset : [
      for a in s.address : a.ip
    ]
  ])
  wl_templates = [
    for f in fileset(local.wl_templates_path, "[0-9]*yaml") :
    "${local.wl_templates_path}/${f}"
  ]
  wl_templates_path = pathexpand(var.workload_config.templates_path)
}

data "google_client_config" "identity" {}

provider "kubernetes" {
  host = join("", [
    "https://connectgateway.googleapis.com/v1/",
    "projects/${local.fleet_project.number}/",
    "locations/global/gkeMemberships/${var.cluster_name}"
  ])
  token = data.google_client_config.identity.access_token
}

resource "kubernetes_namespace" "workload" {
  metadata {
    name = var.workload_config.namespace
  }
  depends_on = [module.fleet]
}

resource "kubernetes_manifest" "workload" {
  for_each = toset(local.wl_templates)
  manifest = yamldecode(templatefile(each.value, {
    image              = local.wl_image
    namespace          = var.workload_config.namespace
    statefulset_config = var.workload_config.statefulset_config
  }))
  dynamic "wait" {
    for_each = strcontains(each.key, "statefulset") ? [""] : []
    content {
      fields = {
        "status.availableReplicas" = var.workload_config.statefulset_config.replicas
      }
    }
  }
  timeouts {
    create = "30m"
  }
  depends_on = [kubernetes_namespace.workload]
}

data "kubernetes_endpoints_v1" "cluster_nodes" {
  metadata {
    name      = "redis-cluster"
    namespace = var.workload_config.namespace
  }
  depends_on = [kubernetes_manifest.workload]
}

resource "kubernetes_manifest" "cluster-start" {
  manifest = yamldecode(templatefile("${local.wl_templates_path}/start-cluster.yaml", {
    image     = local.wl_image
    namespace = var.workload_config.namespace
    nodes     = [for n in local.wl_nodes : "${n}:6379"]
  }))
  field_manager {
    force_conflicts = true
  }
  depends_on = [kubernetes_namespace.workload]
}
