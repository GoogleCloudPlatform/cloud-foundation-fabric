/**
 * Copyright 2026 Google LLC
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
  crema_config_yaml = templatefile("${path.module}/crema/crema-config.yaml.tpl", {
    cooldown_period                    = var.crema_config.cooldown_period
    github_app_id                      = var.github_config.app_id
    github_app_installation_id         = var.github_config.installation_id
    github_app_private_key_secret_name = module.secrets.secrets["github-app-private-key"].secret_id
    github_org                         = var.github_config.org
    max_replicas                       = var.runner_config.max_replicas
    min_replicas                       = var.runner_config.min_replicas
    polling_interval                   = var.crema_config.polling_interval
    project_id                         = module.project.project_id
    region                             = local.location
    runner_labels                      = var.runner_config.labels
    target_workflow_queue_length       = var.crema_config.target_workflow_queue_length
    worker_pool_name                   = "${local.prefix}${var.runner_config.worker_pool_name}"
  })
}

resource "google_parameter_manager_regional_parameter" "crema_config" {
  parameter_id = "${local.prefix}crema-config"
  location     = local.location
  project      = module.project.project_id
  format       = "YAML"
}

resource "google_parameter_manager_regional_parameter_version" "crema_config" {
  parameter            = google_parameter_manager_regional_parameter.crema_config.id
  parameter_version_id = "v-${substr(sha256(local.crema_config_yaml), 0, 8)}"
  parameter_data       = local.crema_config_yaml

  lifecycle {
    create_before_destroy = true
  }
}
