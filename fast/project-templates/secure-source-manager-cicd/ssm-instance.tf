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

module "ssm-instance" {
  source          = "../../../modules/secure-source-manager-instance"
  project_id      = var.project_ids.ssm
  location        = var.locations.ssm
  instance_id     = "${local.prefix}dev-0"
  deletion_policy = var.ssm_config.deletion_policy
  private_configs = {
    is_private = true
    ca_pool_id = var.ssm_config.ca_pool_id
    # immutable, so every VPC host project in the org is listed up front
    psc_allowed_projects = var.ssm_config.psc_allowed_projects
    custom_host_config   = var.ssm_config.custom_host_config
  }
  repositories = {}
}
