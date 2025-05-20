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

# tfdoc:file:description Network monitoring dashboards.

locals {
  _dashboard_path = pathexpand(var.factories_config.dashboards)
  dashboard_files = try(fileset(local._dashboard_path, "*.json"), [])
  dashboards = {
    for filename in local.dashboard_files :
    filename => "${local._dashboard_path}/${filename}"
  }
}

resource "google_monitoring_dashboard" "dashboard" {
  for_each       = local.dashboards
  project        = module.landing-project.project_id
  dashboard_json = file(each.value)
  lifecycle {
    ignore_changes = [dashboard_json]
  }
}
