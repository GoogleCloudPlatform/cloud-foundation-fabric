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
  manifest_template_parameters = {
    mysql_config  = var.mysql_config
    namespace     = helm_release.mysql-operator.namespace
    registry_path = var.registry_path
  }
  stage_1_templates = [
    for f in fileset(local.wl_templates_path, "01*yaml") :
    "${local.wl_templates_path}/${f}"
  ]
  stage_2_templates = [
    for f in fileset(local.wl_templates_path, "01*yaml") :
    "${local.wl_templates_path}/${f}"
  ]

  wl_templates_path = (
    var.templates_path == null
    ? "${path.module}/manifest-templates"
    : pathexpand(var.templates_path)
  )
}

resource "helm_release" "mysql-operator" {
  name             = "my-mysql-operator"
  repository       = "https://mysql.github.io/mysql-operator/"
  chart            = "mysql-operator"
  namespace        = var.namespace
  create_namespace = true
  set {
    name  = "image.registry"
    value = var.registry_path
  }
  set {
    name  = "image.repository"
    value = "mysql"
  }
  set {
    name = "envs.imagesDefaultRegistry"
    value = var.registry_path
  }
  set {
    name = "envs.imagesDefaultRepository"
    value = "mysql"
  }
}

resource "kubectl_manifest" "deploy_cluster" {
  for_each = toset(local.stage_2_templates)
  yaml_body = templatefile(each.value, local.manifest_template_parameters)

  timeouts {
    create = "30m"
  }
  depends_on = [helm_release.mysql-operator]
}
