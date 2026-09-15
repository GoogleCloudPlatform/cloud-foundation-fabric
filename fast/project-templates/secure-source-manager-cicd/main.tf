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
  prefix = var.prefix == null ? "" : "${var.prefix}-"
  # name of the reserved load balancer address
  ssm_lb_ip = "${local.prefix}dev-0-ssm-lb"
}

# the instance project belongs to the project factory; it is reused here for
# the one thing this template needs from it, the SSM service agent email, which
# the module derives from the project number instead of reading it. Name and
# number come from the factory tfvars, so this costs no API call: the data
# source path cannot be used, because attributes are the only way to declare
# services_enabled and the agent is not derived for a service the module has
# not been told about. Nothing else about the project is managed here, so agent
# creation and default roles are off — the factory owns both, and leaving them
# on would put the same IAM members in two states.
module "ssm-project" {
  source = "../../../modules/project"
  name   = var.project_ids.ssm
  prefix = null
  project_reuse = {
    use_data_source = false
    attributes = {
      name             = var.project_ids.ssm
      number           = var.number
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
  project_id = var.project_ids.build
  name       = "build-test-0"
  prefix     = var.prefix
  iam_project_roles = {
    (var.project_ids.build) = [
      "roles/logging.logWriter",
      "roles/cloudbuild.workerPoolUser",
    ]
  }
}
