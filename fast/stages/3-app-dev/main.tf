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

# tfdoc:file:description Project and usage dataset.

locals {
  folder_id = "folders/570667342824" #var.folder_ids[var.stage_config.name]
  gke_nodes_sa_roles = [
    "autoscaling.metricsWriter",
    "logging.logWriter",
    "monitoring.viewer",
    "monitoring.metricWriter",
    "stackdriver.resourceMetadata.writer"
  ]
  project_name = "test14-fsi-app-dev-0"
  _cmek_keys_container = toset(compact(flatten([
    [for k, v in var.clusters : try(v.node_config.boot_disk_kms_key, null)],
    [
      for k, v in var.nodepools : [
        for nk, nv in v : try(nv.node_config.boot_disk_kms_key, null)
      ]
    ]
  ])))
  _cmek_keys_pubsub = toset(compact(flatten([
    [for k, v in var.clusters : try(v.enable_features.upgrade_notifications.kms_key_name, null)],
  ])))
  service_encryption_key_ids = {
    for k, v in {
      "container.googleapis.com" = local._cmek_keys_container
      "pubsub.googleapis.com"    = local._cmek_keys_pubsub
    } : k => v if length(v) > 0
  }
}

module "gke-project-0" {
  source          = "../../../modules/project"
  name            = local.project_name
  project_reuse = {
    use_data_source = false
    attributes = {
      name   = local.project_name
      number = "405419313060"
    }
  }
  iam_bindings_additive = {
    for r in local.gke_nodes_sa_roles : "gke-nodes-sa-${r}" => {
      member = module.gke-nodes-service-account.iam_email
      role   = "roles/${r}"
    }
  }
  services = [
    "container.googleapis.com",
    "compute.googleapis.com",
    "pubsub.googleapis.com",
  ]
  service_encryption_key_ids = local.service_encryption_key_ids
}

module "gke-dataset-resource-usage" {
  source        = "../../../modules/bigquery-dataset"
  project_id    = module.gke-project-0.project_id
  id            = "gke_resource_usage"
  friendly_name = "GKE resource usage."
}

module "gke-nodes-service-account" {
  source     = "../../../modules/iam-service-account"
  project_id = module.gke-project-0.project_id
  name       = "gke-node-default"
}
