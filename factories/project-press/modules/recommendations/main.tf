/**
 * Copyright 2021 Google LLC
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

data "external" "recommendations-reports" {
  count = var.recommendations_topic != "" ? 1 : 0
  program = [
    "python3",
    "${path.root}/../scripts/recommendations-reports.py",
    "--config",
    "${path.root}/../config.yaml",
    "--recommendations-config",
    "${path.root}/../recommendationsReports.yaml",
    "--stdin"
  ]

  query = {
    projects = jsonencode(var.projects)
  }
}

locals {
  recommendations = var.recommendations_topic != "" ? jsondecode(data.external.recommendations-reports[0].result.output) : {}
}

resource "google_cloud_scheduler_job" "recommendations-jobs" {
  for_each = local.recommendations

  region  = var.scheduler_region
  project = var.scheduler_project

  name        = format("recommendations-reports-%s", each.key)
  description = format("Recommendations report: %s", each.key)
  schedule    = var.scheduler_cron
  time_zone   = var.scheduler_timezone

  pubsub_target {
    topic_name = var.recommendations_topic
    data       = base64encode(each.value.pubsub_message_str)
  }
}

