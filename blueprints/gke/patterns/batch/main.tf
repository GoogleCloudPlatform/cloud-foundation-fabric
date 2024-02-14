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

locals {
  wl_templates_path = "${path.module}/manifest-templates"
}


resource "kubectl_manifest" "kueue_namespace_manifest" {
  yaml_body = <<EOT
apiVersion: v1
kind: Namespace
metadata:
  labels:
    control-plane: controller-manager
  name: ${var.kueue_namespace}
EOT
}

data "kubectl_file_documents" "kueue_docs" {
  content = file("${local.wl_templates_path}/kueue.yaml")
}

data "kubectl_path_documents" "cluster_resources_docs" {
  pattern = "${local.wl_templates_path}/cluster-resources/*.yaml"
}

resource "kubectl_manifest" "kueue_manifest" {
  for_each           = data.kubectl_file_documents.kueue_docs.manifests
  yaml_body          = each.value
  override_namespace = var.kueue_namespace
  depends_on         = [kubectl_manifest.kueue_namespace_manifest]
}

resource "kubectl_manifest" "cluster_resources_manifests" {
  for_each   = toset(data.kubectl_path_documents.cluster_resources_docs.documents)
  yaml_body  = each.value
  depends_on = [kubectl_manifest.kueue_manifest]
}


resource "kubectl_manifest" "team_namespace_manifests" {
  for_each  = toset(var.team_namespaces)
  yaml_body = <<EOT
apiVersion: v1
kind: Namespace
metadata:
  name: ${each.value}
EOT
}

resource "kubectl_manifest" "local_queues_manifests" {
  for_each           = toset(var.team_namespaces)
  yaml_body          = file("${local.wl_templates_path}/team-resources/local-queue.yaml")
  override_namespace = each.value
  depends_on = [
    kubectl_manifest.cluster_resources_manifests,
    kubectl_manifest.team_namespace_manifests
  ]
}

resource "local_file" "job_manifest_files" {
  for_each = toset(var.team_namespaces)
  content = templatefile("${local.wl_templates_path}/team-resources/job.yaml", {
    namespace = each.value
  })
  filename = "${path.module}/job-${each.value}.yaml"
}
