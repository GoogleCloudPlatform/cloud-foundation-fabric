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
  wl_templates = [
    for f in fileset(local.wl_templates_path, "[0-9]*yaml") :
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

resource "helm_release" "strimzi_operator" {
  name       = "strimzi-operator"
  repository = "https://strimzi.io/charts"
  chart      = "strimzi-kafka-operator"
  namespace  = kubernetes_namespace.default.metadata.0.name

  # TODO: to understand
  # set {
  #   name  = "watchNamespaces"
  #   value = "{${var.namespace}}"
  # }
}

# resource "kubernetes_manifest" "default" {
#   for_each = toset(local.wl_templates)
#   manifest = yamldecode(templatefile(each.value, {
#     namespace = kubernetes_namespace.default.metadata.0.name
#     name      = var.statefulset_config.name
#     version   = var.statefulset_config.version
#   }))
#   timeouts {
#     create = "30m"
#   }
#   depends_on = [helm_release.strimzi_operator]
# }

resource "kubectl_manifest" "default" {
  for_each = toset(local.wl_templates)
  yaml_body = format("%#v", yamldecode(templatefile(each.value, {
    namespace = kubernetes_namespace.default.metadata.0.name
    name      = var.statefulset_config.name
    version   = var.statefulset_config.version
  })))
  timeouts {
    create = "30m"
  }
  depends_on = [helm_release.strimzi_operator]
}
