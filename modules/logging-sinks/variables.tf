/**
 * Copyright 2019 Google LLC
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

variable "default_options" {
  description = "Default options used for sinks where no specific options are set."
  type = object({
    bigquery_partitioned_tables = bool
    include_children            = bool
    unique_writer_identity      = bool
  })
  default = {
    bigquery_partitioned_tables = true
    include_children            = true
    unique_writer_identity      = false
  }
}

variable "destinations" {
  description = "Map of destinations by sink name."
  type        = map(string)
}

variable "parent" {
  description = "Resource where the sink will be created, eg 'organizations/nnnnnnnn'."
  type        = string
}

variable "sink_options" {
  description = "Optional map of sink name / sink options. If no options are specified for a sink defaults will be used."
  type = map(object({
    bigquery_partitioned_tables = bool
    include_children            = bool
    unique_writer_identity      = bool
  }))
  default = {}
}

variable "sinks" {
  description = "Map of sink name / sink filter."
  type        = map(string)
}
