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

module "factory" {
  source = "../../../modules/project-factory"
  data_defaults = {
    storage_location = local.location
  }
  data_merges = {
    services = [
      "logging.googleapis.com",
      "monitoring.googleapis.com"
    ]
  }
  data_overrides = {
    billing_account = var.billing_account.id
    prefix          = local.prefix
  }
  factories_config = {}
  factories_data = {
    hierarchy = local.dd_folders
    projects = merge(
      local.dd_projects,
      local.dp_projects
    )
  }
}
