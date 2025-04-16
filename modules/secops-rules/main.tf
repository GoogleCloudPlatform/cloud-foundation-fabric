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
  _secops_rules_path = pathexpand(coalesce(var.factories_config.rules_defs, "-"))
  reference_lists    = try(yamldecode(file(var.factories_config.reference_lists)), var.reference_lists_config)
  reference_lists_entries = {
    for k, v in local.reference_lists : k => split("\n", file("${var.factories_config.reference_lists_defs}/${k}.txt"))
  }
  reference_list_type_mapping = {
    STRING = "REFERENCE_LIST_SYNTAX_TYPE_PLAIN_TEXT_STRING"
    REGEX  = "REFERENCE_LIST_SYNTAX_TYPE_REGEX"
    CIDR   = "REFERENCE_LIST_SYNTAX_TYPE_CIDR"
  }
  secops_rules = {
    for file_name in fileset(local._secops_rules_path, "*.yaral") :
    replace(file_name, ".yaral", "") => file("${local._secops_rules_path}/${file_name}")
  }
  secops_rule_deployment = try(yamldecode(file(var.factories_config.rules)), var.rules_config)
}

resource "google_chronicle_reference_list" "default" {
  for_each          = local.reference_lists
  project           = var.project_id
  location          = var.tenant_config.region
  instance          = var.tenant_config.customer_id
  reference_list_id = each.key
  description       = each.value.description
  dynamic "entries" {
    for_each = local.reference_lists_entries[each.key]
    content {
      value = entries.value
    }
  }
  syntax_type = local.reference_list_type_mapping[each.value.type]
}

resource "google_chronicle_rule" "default" {
  for_each        = local.secops_rule_deployment
  project         = var.project_id
  location        = var.tenant_config.region
  instance        = var.tenant_config.customer_id
  text            = local.secops_rules[each.key]
  deletion_policy = "FORCE"
  depends_on = [
    google_chronicle_reference_list.default
  ]
}

resource "google_chronicle_rule_deployment" "default" {
  for_each      = local.secops_rule_deployment
  project       = var.project_id
  location      = var.tenant_config.region
  instance      = var.tenant_config.customer_id
  rule          = google_chronicle_rule.default[each.key].rule_id
  enabled       = each.value.enabled
  alerting      = each.value.alerting
  archived      = each.value.archived
  run_frequency = each.value.run_frequency
}
