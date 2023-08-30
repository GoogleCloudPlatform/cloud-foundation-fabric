/**
 * Copyright 2023 Google LLC
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
  _resolved_datascan_rules = {
    for datascan_name, datascan_configs in local._datascan_specs :
    datascan_name => merge(
      local._datascan_defaults,
      datascan_configs,
      var.merge_labels_with_defaults ? { 
        labels = merge(
          try(local._datascan_defaults.labels, {}), 
          try(datascan_configs.labels, {})) 
        } : {},
      var.merge_iam_bindings_defaults ? { 
        iam_bindings = merge(
          try(local._datascan_defaults.iam_bindings, {}), 
          try(datascan_configs.iam_bindings, {}))
        } : {},
      !can(datascan_configs.data_profile_spec) ? {} : {
        data_profile_spec = datascan_configs.data_profile_spec != null ? datascan_configs.data_profile_spec : {} 
      },
      !can(datascan_configs.data_quality_spec) ? {} : {
        data_quality_spec = {
          sampling_percent = try(datascan_configs.data_quality_spec.sampling_percent, null)
          row_filter       = try(datascan_configs.data_quality_spec.row_filter, null)
          rules = [
            for rule in datascan_configs.data_quality_spec.rules : merge(
              {
                column = try(
                  rule.column,
                  rule.use_rule_template.override.column,
                  local._datascan_rule_templates.rule_templates[rule.use_rule_template.name].column,
                  null
                ),
                dimension = try(
                  rule.dimension,
                  rule.use_rule_template.override.dimension,
                  local._datascan_rule_templates.rule_templates[rule.use_rule_template.name].dimension
                ),
                ignore_null = try(
                  rule.ignore_null,
                  rule.use_rule_template.override.ignore_null,
                  local._datascan_rule_templates.rule_templates[rule.use_rule_template.name].ignore_null,
                  null
                ),
                threshold = try(
                  rule.threshold,
                  rule.use_rule_template.override.threshold,
                  local._datascan_rule_templates.rule_templates[rule.use_rule_template.name].threshold,
                  null
                ),
              },
              {
                for key, value in {
                  non_null_expectation = try(
                    rule.non_null_expectation,
                    local._datascan_rule_templates.rule_templates[rule.use_rule_template.name].non_null_expectation,
                    null
                  ),
                  uniqueness_expectation = try(
                    rule.uniqueness_expectation,
                    local._datascan_rule_templates.rule_templates[rule.use_rule_template.name].uniqueness_expectation,
                    null
                  ),
                  range_expectation = try(
                    rule.range_expectation,
                    merge(
                      try(local._datascan_rule_templates.rule_templates[rule.use_rule_template.name].range_expectation, {}),
                      try(rule.use_rule_template.override.range_expectation, {}),
                    ),
                    null
                  ),
                  regex_expectation = try(
                    rule.regex_expectation,
                    merge(
                      try(local._datascan_rule_templates.rule_templates[rule.use_rule_template.name].regex_expectation, {}),
                      try(rule.use_rule_template.override.regex_expectation, {}),
                    ),
                    null
                  ),
                  set_expectation = try(
                    rule.set_expectation,
                    merge(
                      try(local._datascan_rule_templates.rule_templates[rule.use_rule_template.name].set_expectation, {}),
                      try(rule.use_rule_template.override.set_expectation, {}),
                    ),
                    null
                  ),
                  statistic_range_expectation = try(
                    rule.statistic_range_expectation,
                    merge(
                      try(local._datascan_rule_templates.rule_templates[rule.use_rule_template.name].statistic_range_expectation, {}),
                      try(rule.use_rule_template.override.statistic_range_expectation, {}),
                    ),
                    null
                  ),
                  row_condition_expectation = try(
                    rule.row_condition_expectation,
                    merge(
                      try(local._datascan_rule_templates.rule_templates[rule.use_rule_template.name].row_condition_expectation, {}),
                      try(rule.use_rule_template.override.row_condition_expectation, {}),
                    ),
                    null
                  ),
                  table_condition_expectation = try(
                    rule.table_condition_expectation,
                    merge(
                      try(local._datascan_rule_templates.rule_templates[rule.use_rule_template.name].table_condition_expectation, {}),
                      try(rule.use_rule_template.override.table_condition_expectation, {}),
                    ),
                    null
                  ),
                  } : key => value if(
                  value != null &&
                  (
                    length(value == null ? {} : value) > 0 ||
                    contains(["uniqueness_expectation", "non_null_expectation"], key)
                  )
                )
              }
            )
          ]
        }
      }
    )
  }
}
