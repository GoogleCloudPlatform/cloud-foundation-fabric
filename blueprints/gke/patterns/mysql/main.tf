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
    mysql_config   = var.mysql_config
    namespace      = helm_release.mysql-operator.namespace
    registry_path  = var.registry_path
    mysql_password = random_password.mysql_password.result
  }
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

resource "random_password" "mysql_password" {
  length  = 28
  lower   = true
  numeric = true
  upper   = true
  special = false
}

resource "helm_release" "mysql-operator" {
  name             = "my-mysql-operator"
  repository       = "https://mysql.github.io/mysql-operator/"
  chart            = "mysql-operator"
  namespace        = var.namespace
  create_namespace = true
  set {
    name  = "envs.k8sClusterDomain"
    value = "cluster.local" # avoid lookups during operator startups which sometimes fail
  }
}

resource "kubectl_manifest" "dependencies" {
  for_each  = toset(local.stage_1_templates)
  yaml_body = templatefile(each.value, local.manifest_template_parameters)

  override_namespace = helm_release.mysql-operator.namespace

  timeouts {
    create = "30m"
  }
}


resource "kubectl_manifest" "deploy_cluster" {
  for_each  = toset(local.stage_2_templates)
  yaml_body = templatefile(each.value, local.manifest_template_parameters)

  override_namespace = helm_release.mysql-operator.namespace

  timeouts {
    create = "30m"
  }
  depends_on = [kubectl_manifest.dependencies]
}

module "bastion" {
  source = "../../../../modules/compute-vm"

  name = "bastion"
  network_interfaces = [{
    addresses = {
      internal = "10.0.0.10"
    }
    network    = var.created_resources.vpc_id
    subnetwork = var.created_resources.subnet_id
  }]
  project_id    = var.project_id
  zone          = "${var.region}-b"
  instance_type = "n2-standard-2"
  service_account = {
    auto_create = true
    #      email       = module.compute-sa.email
    scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
