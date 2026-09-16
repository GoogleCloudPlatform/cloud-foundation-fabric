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
  build_project = (
    var.projects_config.build != null
    ? var.projects_config.build
    : var.projects_config.ssm
  )
  prefix    = var.prefix == null ? "" : "${var.prefix}-"
  ssm_lb_ip = "${local.prefix}dev-0-ssm-lb"
}

module "ssm-project" {
  source = "../../../modules/project"
  name   = var.projects_config.ssm.project_id
  prefix = null
  project_reuse = {
    use_data_source = false
    attributes = {
      name             = var.projects_config.ssm.project_id
      number           = var.projects_config.ssm.number
      services_enabled = ["securesourcemanager.googleapis.com"]
    }
  }
  service_agents_config = {
    create_primary_agents = false
    grant_default_roles   = false
  }
}

module "build-sa-test" {
  source     = "../../../modules/iam-service-account"
  project_id = local.build_project.project_id
  name       = "build-test-0"
  prefix     = var.prefix
  iam_project_roles = {
    (local.build_project.project_id) = [
      "roles/logging.logWriter",
      "roles/cloudbuild.workerPoolUser",
    ]
  }
}
