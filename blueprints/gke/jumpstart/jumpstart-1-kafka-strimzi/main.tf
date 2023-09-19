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

resource "helm_release" "strimzi-operator" {
  name       = "strimzi-operator"
  repository = "https://strimzi.io/charts"
  chart      = "strimzi-kafka-operator"
  namespace  = kubernetes_namespace.default.metadata.0.name

  # set {
  #   name  = "watchNamespaces"
  #   value = "{${var.namespace}}"
  # }
}

resource "helm_release" "kafka-cluster" {
  name       = "kafka-cluster"
  chart      = "./kafka-cluster-chart"
  namespace  = kubernetes_namespace.default.metadata.0.name
  depends_on = [helm_release.strimzi-operator]
}
