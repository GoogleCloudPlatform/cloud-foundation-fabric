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

variable "data" {
  description = "The data source for DataScan. The input variable 'data' should be an object containing a single key-value pair that can be one of: * `entity`: The Dataplex entity that represents the data source (e.g. BigQuery table) for DataScan, of the form: `projects/{project_number}/locations/{locationId}/lakes/{lakeId}/zones/{zoneId}/entities/{entityId}`. * `resource`: The service-qualified full resource name of the cloud resource for a DataScan job to scan against. The field could be: BigQuery table of type 'TABLE' for DataProfileScan/DataQualityScan format, e.g: `//bigquery.googleapis.com/projects/PROJECT_ID/datasets/DATASET_ID/tables/TABLE_ID`."
  type = object({
    entity   = optional(string)
    resource = optional(string)
  })
  validation {
    condition     = length([for k, v in var.data : v if contains(["resource", "entity"], k) && v != null]) == 1
    error_message = "Datascan data must specify one of 'entity', 'resource'."
  }
}

variable "execution_trigger" {
  description = "The input variable 'execution_trigger' specifies when a scan should be triggered. If not specified, the default is `on_demand`, which means the scan will not run until the user calls `dataScans.run` API. Alternatively, you can set `execution_trigger` to `scheduled` scheduled to run periodically based on a cron schedule expression."
  type = object({
    on_demand = optional(object({}))
    schedule = optional(object({
      cron = string
    }))
  })
  default = {
    on_demand = {}
  }
  validation {
    condition     = length([for k, v in var.execution_trigger : v if contains(["on_demand", "schedule"], k) && v != null]) == 1
    error_message = "Datascan execution_spec_trigger field must contain only one of 'on_demand' containing an empty object, or 'schedule' containing the field 'cron'."
  }
}

variable "group_iam" {
  description = "Authoritative IAM binding for organization groups, in {GROUP_EMAIL => [ROLES]} format. Group emails need to be static. Can be used in combination with the `iam` variable."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "iam" {
  description = "Dataplex AutoDQ  IAM bindings in {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "iam_additive" {
  description = "IAM additive bindings in {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "iam_additive_members" {
  description = "IAM additive bindings in {MEMBERS => [ROLE]} format. This might break if members are dynamic values."
  type        = map(list(string))
  default     = {}
}

variable "iam_policy" {
  description = "IAM authoritative policy in {ROLE => [MEMBERS]} format. Roles and members not explicitly listed will be cleared, use with extreme caution."
  type        = map(list(string))
  default     = null
}

variable "incremental_field" {
  description = "The unnested field (of type Date or Timestamp) that contains values which monotonically increase over time. If not specified, a data scan will run for all data in the table."
  type        = string
  default     = null
}

variable "labels" {
  description = "Resource labels."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "name" {
  description = "Name of Dataplex AutoDQ Scan."
  type        = string
}

variable "prefix" {
  description = "Optional prefix used to generate Dataplex AutoDQ DataScan ID."
  type        = string
  default     = null
}

variable "project_id" {
  description = "Required.The ID of the project where the Dataplex AutoDQ Scans will be created."
  type        = string
}

variable "region" {
  description = "Region for the Dataplex AutoDQ Scan."
  type        = string
}

variable "row_filter" {
  description = "A filter applied to all rows in a single DataScan job. The filter needs to be a valid SQL expression for a WHERE clause in BigQuery standard SQL syntax. Example: col1 >= 0 AND col2 < 10"
  type        = string
  default     = null
}

variable "rules" {
  description = "Data Quality validation rules. If not provided, the DataScan will be created as a Data Profiling scan."
  nullable    = true
  default     = null
  type = list(object({
    column               = optional(string)
    ignore_null          = optional(bool)
    dimension            = string
    threshold            = optional(number)
    non_null_expectation = optional(object({}))
    range_expectation = optional(object({
      min_value          = optional(number)
      max_value          = optional(number)
      strict_min_enabled = optional(bool)
      strict_max_enabled = optional(bool)
    }))
    regex_expectation = optional(object({
      regex = string
    }))
    set_expectation = optional(object({
      values = list(string)
    }))
    uniqueness_expectation = optional(object({}))
    statistic_range_expectation = optional(object({
      statistic          = string
      min_value          = optional(number)
      max_value          = optional(number)
      strict_min_enabled = optional(bool)
      strict_max_enabled = optional(bool)
    }))
    row_condition_expectation = optional(object({
      sql_expression = string
    }))
    table_condition_expectation = optional(object({
      sql_expression = string
    }))
  }))
  validation {
    condition = alltrue([
      for rule in coalesce(var.rules, []) :
    contains(["COMPLETENESS", "ACCURACY", "CONSISTENCY", "VALIDITY", "UNIQUENESS", "INTEGRITY"], rule.dimension)])
    error_message = "Datascan 'dimension' field in 'data_quality_spec' must be one of ['COMPLETENESS', 'ACCURACY', 'CONSISTENCY', 'VALIDITY', 'UNIQUENESS', 'INTEGRITY']."
  }
  validation {
    condition = alltrue([
      for rule in coalesce(var.rules, []) :
      length([
        for k, v in rule :
        v if contains(["non_null_expectation", "range_expectation", "regex_expectation", "set_expectation", "uniqueness_expectation", "statistic_range_expectation", "row_condition_expectation", "table_condition_expectation"], k) && v != null
    ]) == 1])
    error_message = "Datascan rule must contain a key that is one of ['non_null_expectation', 'range_expectation', 'regex_expectation', 'set_expectation', 'uniqueness_expectation', 'statistic_range_expectation', 'row_condition_expectation', 'table_condition_expectation]."
  }
}

variable "sampling_percent" {
  description = "The percentage of the records to be selected from the dataset for DataScan. Value can range between 0.0 and 100.0 with up to 3 significant decimal digits. Sampling is not applied if samplingPercent is not specified, 0 or 100."
  type        = number
  default     = null
}