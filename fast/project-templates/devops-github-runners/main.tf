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
  crema_sa_email = (
    var.crema_config.service_account == null
    ? "crema-autoscaler-sa@${local.project_id}.iam.gserviceaccount.com"
    : lookup(
      local.ctx.iam_principals,
      var.crema_config.service_account,
      var.crema_config.service_account
    )
  )
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local.ctx_p}${k}:${kk}" => vv
    }
  }
  ctx_p    = "$"
  location = lookup(local.ctx.locations, var.location, var.location)
  prefix   = var.prefix == null ? "" : "${var.prefix}-"
  project_id = lookup(
    local.ctx.project_ids,
    var.project_config.project_id,
    var.project_config.project_id
  )
  worker_sa_email = (
    var.runner_config.service_account == null
    ? "worker-pool-sa@${local.project_id}.iam.gserviceaccount.com"
    : lookup(
      local.ctx.iam_principals,
      var.runner_config.service_account,
      var.runner_config.service_account
    )
  )
}

module "project" {
  source = "../../../modules/project"
  name   = local.project_id
  prefix = null
  project_reuse = {
    use_data_source = false
    attributes = {
      name   = local.project_id
      number = var.project_config.number
      services_enabled = [
        "artifactregistry.googleapis.com",
        "cloudbuild.googleapis.com",
        "compute.googleapis.com",
        "iam.googleapis.com",
        "logging.googleapis.com",
        "monitoring.googleapis.com",
        "parametermanager.googleapis.com",
        "run.googleapis.com",
        "secretmanager.googleapis.com",
        "storage.googleapis.com",
      ]
    }
  }
  service_agents_config = {
    create_primary_agents = false
    grant_default_roles   = false
  }
}
