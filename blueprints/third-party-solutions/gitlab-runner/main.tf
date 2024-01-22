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
  runner_config_type = [for key, value in var.gitlab_runner_config.executors_config : key if value != null][0]
  runner_startup_script_config = {
    gitlab_hostname      = var.gitlab_config.hostname
    gitlab_ca_cert       = base64encode(var.gitlab_config.ca_cert_pem)
    token                = var.gitlab_runner_config.authentication_token
    gitlab_runner_config = base64encode(templatefile("${path.module}/assets/config/${local.runner_config_type}_config.toml.tpl", var.gitlab_runner_config.executors_config[local.runner_config_type]))
    gitlab_executor_type = replace(local.runner_config_type, "_", "-")
  }
}

resource "google_project_iam_custom_role" "gitlab_runner_manager_role" {
  project     = var.project_id
  role_id     = "gitlabRunnerManagerRole"
  title       = "Gitlab Runner Manager custom role"
  description = "Custom GCP Role for Docker Autoscaler manager SA."
  permissions = [
    "compute.instanceGroupManagers.get", "compute.instanceGroupManagers.update",
    "compute.instances.get", "compute.instances.setMetadata"
  ]
}

resource "google_project_iam_member" "gitlab_runner_manager_role" {
  project = var.project_id
  role    = google_project_iam_custom_role.gitlab_runner_manager_role.id
  member  = "serviceAccount:${module.gitlab-runner.service_account.email}"
}

resource "google_service_account_iam_member" "admin-account-iam" {
  service_account_id = module.gitlab-runner-template.0.service_account.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${module.gitlab-runner.service_account.email}"
}