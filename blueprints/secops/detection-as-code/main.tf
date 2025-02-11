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
  secops_rules = {
    for file_name in fileset("rules", "*.yaral") : replace(file_name, ".yaral", "") => file("rules/${file_name}")
  }
  secops_rule_deployment = yamldecode(file(var.secops_rule_config))
}

resource "google_chronicle_rule" "rule" {
  for_each = local.secops_rule_deployment
  provider = "google-beta"
  project  = var.secops_config.project
  location = var.secops_config.location
  instance = var.secops_config.instance
  text     = local.secops_rules[each.key]
}

resource "google_chronicle_rule_deployment" "rule_deployment" {
  for_each      = local.secops_rule_deployment
  provider      = "google-beta"
  project       = var.secops_config.project
  location      = var.secops_config.location
  instance      = var.secops_config.instance
  rule          = google_chronicle_rule.rule[each.key].rule_id
  enabled       = each.value.enabled
  alerting      = each.value.alerting
  archived      = each.value.archived
  run_frequency = each.value.run_frequency
}
