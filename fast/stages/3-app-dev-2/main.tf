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
  gke_nodes_sa_roles = [
    "autoscaling.metricsWriter",
    "logging.logWriter",
    "monitoring.viewer",
    "monitoring.metricWriter",
    "stackdriver.resourceMetadata.writer"
  ]
  project_name         = var.project_id
  _cmek_keys_compute   = var.compute_kms_key != null ? [var.compute_kms_key] : []
  _cmek_keys_container = var.gke_kms_key != null ? [var.gke_kms_key] : []
  _cmek_keys_pubsub    = var.pubsub_kms_key != null ? [var.pubsub_kms_key] : []
  service_encryption_key_ids = {
    "compute.googleapis.com"   = local._cmek_keys_compute
    "container.googleapis.com" = local._cmek_keys_container
    "pubsub.googleapis.com"    = local._cmek_keys_pubsub
  }
}
