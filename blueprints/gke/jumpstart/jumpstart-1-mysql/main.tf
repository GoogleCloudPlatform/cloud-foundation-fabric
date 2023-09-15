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
  #  TODO: should just the prefix in the filename be the number of the stage?
  stage_1_templates = [
    for f in fileset(local.wl_templates_path, "01*yaml") :
    "${local.wl_templates_path}/${f}"
  ]
  stage_2_templates = [
    for f in fileset(local.wl_templates_path, "02*yaml") :
    "${local.wl_templates_path}/${f}"
  ]


  wl_templates_path = (
  var.templates_path == null
  ? "${path.module}/manifest-templates"
  : pathexpand(var.templates_path)
  )
}

resource "kubernetes_namespace" "default" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_manifest" "stage1" {
  for_each = toset(local.stage_1_templates)
  manifest = yamldecode(templatefile(each.value, {
    namespace = kubernetes_namespace.default.metadata.0.name
    replicas_count = 3
  }))
  dynamic "wait" {
    for_each = strcontains(each.key, "statefulset") ? [""] : []
    content {
      fields = {
        "status.readyReplicas" = 3
      }
    }
  }
  timeouts {
    create = "30m"
  }
}

resource "kubernetes_manifest" "stage2" {
  for_each = toset(local.stage_2_templates)
  manifest = yamldecode(templatefile(each.value, {
    namespace = kubernetes_namespace.default.metadata.0.name
    replicas_count = 3
  }))
  dynamic "wait" {
    for_each = strcontains(each.key, "statefulset") ? [""] : []
    content {
      fields = {
        "status.readyReplicas" = 3
      }
    }
  }
  timeouts {
    create = "30m"
  }
  depends_on = [kubernetes_manifest.stage1]
}
