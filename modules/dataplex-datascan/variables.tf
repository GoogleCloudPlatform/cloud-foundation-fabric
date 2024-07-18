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
  description = "The data source for DataScan. The source can be either a Dataplex `entity` or a BigQuery `resource`."
  type = object({
    entity   = optional(string)
    resource = optional(string)
  })
  validation {
    condition     = length([for k, v in var.data : v if contains(["resource", "entity"], k) && v != null]) == 1
    error_message = "Datascan data must specify one of 'entity', 'resource'."
  }
}

variable "data_profile_spec" {
  description = "DataProfileScan related setting. Variable descriptions are provided in https://cloud.google.com/dataplex/docs/reference/rest/v1/DataProfileSpec."
  default     = null
  type = object({
    sampling_percent = optional(number)
    row_filter       = optional(string)
  })
}

variable "data_quality_spec" {
  description = "DataQualityScan related setting. Variable descriptions are provided in https://cloud.google.com/dataplex/docs/reference/rest/v1/DataQualitySpec."
  default     = null
  type = object({
    sampling_percent = optional(number)
    row_filter       = optional(string)
    post_scan_actions = optional(object({
      bigquery_export = optional(object({
        results_table = optional(string)
      }))
    }))
    rules = list(object({
      column               = optional(string)
      ignore_null          = optional(bool, null)
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
      sql_assertion = optional(object({
        sql_statement = string
      }))
    }))
  })
}

variable "description" {
  description = "Custom description for DataScan."
  default     = null
  type        = string
}

variable "execution_schedule" {
  description = "Schedule DataScan to run periodically based on a cron schedule expression. If not specified, the DataScan is created with `on_demand` schedule, which means it will not run until the user calls `dataScans.run` API."
  type        = string
  default     = null
}

variable "factories_config" {
  description = "Paths to data files and folders that enable factory functionality."
  type = object({
    data_quality_spec = optional(string)
  })
  nullable = false
  default  = {}
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
  description = "Name of Dataplex Scan."
  type        = string
}

variable "prefix" {
  description = "Optional prefix used to generate Dataplex DataScan ID."
  type        = string
  default     = null
}

variable "project_id" {
  description = "The ID of the project where the Dataplex DataScan will be created."
  type        = string
}

variable "region" {
  description = "Region for the Dataplex DataScan."
  type        = string
}
