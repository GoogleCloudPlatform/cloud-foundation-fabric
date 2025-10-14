/**
 * Copyright 2025 Google LLC
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
  monitoring_project_id          = module.factory.project_ids["log-0"]
  monitoring_project_number      = module.factory.project_numbers["log-0"]
  monitoring_logging_bucket_name = module.factory.projects["log-0"]["log_buckets"]["log-0/audit-logs"]
}

module "monitoring-alerts-project" {
  source = "../../../modules/project"
  name   = local.monitoring_project_id

  project_reuse = {
    use_data_source = false
    attributes = {
      name   = local.monitoring_project_id
      number = local.monitoring_project_number
    }
  }
  context = {
    logging_bucket_names = {
      "organization-log-bucket" : local.monitoring_logging_bucket_name
    }
  }
  factories_config = {
    observability = "${local.paths.organization}/observability"
  }

  depends_on = [module.factory]
}
