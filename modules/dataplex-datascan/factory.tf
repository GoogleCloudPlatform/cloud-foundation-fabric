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
  _factory_data = (
    var.factories_config.data_quality_spec == null
    ? null
    : yamldecode(file(pathexpand(var.factories_config.data_quality_spec)))
  )
  factory_data = {
    post_scan_actions = try(
      local._factory_data.postScanActions,
      local._factory_data.post_scan_actions,
      null
    )
    row_filter = try(
      local._factory_data.rowFilter,
      local._factory_data.row_filter,
      null
    )
    rules = [
      for rule in try(local._factory_data.rules, []) : {
        column      = try(rule.column, null)
        ignore_null = try(rule.ignoreNull, rule.ignore_null, null)
        dimension   = rule.dimension
        threshold   = try(rule.threshold, null)
        non_null_expectation = try(
          rule.nonNullExpectation, rule.non_null_expectation, null
        )
        range_expectation = (
          can(rule.rangeExpectation) || can(rule.range_expectation)
          ? {
            min_value = try(
              rule.rangeExpectation.minValue,
              rule.range_expectation.min_value,
              null
            )
            max_value = try(
              rule.rangeExpectation.maxValue,
              rule.range_expectation.max_value,
              null
            )
            strict_min_enabled = try(
              rule.rangeExpectation.strictMinEnabled,
              rule.range_expectation.strict_min_enabled,
              null
            )
            strict_max_enabled = try(
              rule.rangeExpectation.strictMaxEnabled,
              rule.range_expectation.strict_max_enabled,
              null
            )
          }
          : null
        )
        regex_expectation = (
          can(rule.regexExpectation) || can(rule.regex_expectation)
          ? {
            regex = try(
              rule.regexExpectation.regex, rule.regex_expectation.regex, null
            )
          }
          : null
        )
        set_expectation = (
          can(rule.setExpectation) || can(rule.set_expectation)
          ? {
            values = try(
              rule.setExpectation.values, rule.set_expectation.values, null
            )
          }
          : null
        )
        uniqueness_expectation = try(
          rule.uniquenessExpectation, rule.uniqueness_expectation, null
        )
        statistic_range_expectation = (
          can(rule.statisticRangeExpectation) || can(rule.statistic_range_expectation)
          ? {
            statistic = try(
              rule.statisticRangeExpectation.statistic,
              rule.statistic_range_expectation.statistic
            )
            min_value = try(
              rule.statisticRangeExpectation.minValue,
              rule.statistic_range_expectation.min_value,
              null
            )
            max_value = try(
              rule.statisticRangeExpectation.maxValue,
              rule.statistic_range_expectation.max_value,
              null
            )
            strict_min_enabled = try(
              rule.statisticRangeExpectation.strictMinEnabled,
              rule.statistic_range_expectation.strict_min_enabled,
              null
            )
            strict_max_enabled = try(
              rule.statisticRangeExpectation.strictMaxEnabled,
              rule.statistic_range_expectation.strict_max_enabled,
              null
            )
          }
          : null
        )
        row_condition_expectation = (
          can(rule.rowConditionExpectation) || can(rule.row_condition_expectation)
          ? {
            sql_expression = try(
              rule.rowConditionExpectation.sqlExpression,
              rule.row_condition_expectation.sql_expression,
              null
            )
          }
          : null
        )
        table_condition_expectation = (
          can(rule.tableConditionExpectation) || can(rule.table_condition_expectation)
          ? {
            sql_expression = try(
              rule.tableConditionExpectation.sqlExpression,
              rule.table_condition_expectation.sql_expression,
              null
            )
          }
          : null
        )
        sql_assertion = (
          can(rule.sqlAssertion) || can(rule.sql_assertion)
          ? {
            sql_statement = try(
              rule.sqlAssertion.sqlStatement,
              rule.sql_assertion.sql_statement,
              null
            )
          }
          : null
        )
      }
    ]
    sampling_percent = try(
      local._factory_data.samplingPercent,
      local._factory_data.sampling_percent,
      null
    )
  }
}
