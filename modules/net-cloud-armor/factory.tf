# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

locals {
  _factory_rules_folder = try(pathexpand(var.factories_config.rules_folder), null)
  _factory_rule_files = local._factory_rules_folder == null ? [] : [
    for f in try(fileset(local._factory_rules_folder, "**/*.yaml"), []) :
    "${local._factory_rules_folder}/${f}"
  ]
  _factory_file_data = (
    var.factories_config.rules_file_path != null
    ? file(pathexpand(var.factories_config.rules_file_path))
    : "{}"
  )
  _factory_file_rules = yamldecode(local._factory_file_data)
  _factory_folder_rules = merge(
    {},
    [
      for f in local._factory_rule_files :
      yamldecode(file(f))
    ]...
  )
  _factory_raw_rules = merge(local._factory_file_rules, local._factory_folder_rules)

  factory_rules = {
    for k, v in local._factory_raw_rules : k => {
      action      = v.action
      priority    = v.priority
      description = lookup(v, "description", null)
      preview     = lookup(v, "preview", false)
      expression = (
        lookup(v, "preconfigured_waf", null) != null
        ? "evaluatePreconfiguredWaf('${v.preconfigured_waf}')"
        : lookup(v, "threat_intel_feed", null) != null
        ? "evaluateThreatIntelligence('${v.threat_intel_feed}')"
        : lookup(v, "expression", null)
      )
      src_ip_ranges      = lookup(v, "src_ip_ranges", null)
      header_action      = lookup(v, "header_action", null)
      rate_limit_options = lookup(v, "rate_limit_options", null)
      redirect_options   = lookup(v, "redirect_options", null)
    }
  }
}
