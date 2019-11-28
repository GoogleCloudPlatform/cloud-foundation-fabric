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

variable "project_id" {
  description = "Project ID"
  type        = string
}

variable "datasets" {
  description = "Datatase IDs"
  default     = []
  type        = list
  # type = list(object({
  #   id          = string
  #   name        = string
  #   description = string
  #   location    = string
  #   # labels = map(string) # optional
  #   # default_partition_expiration_ms = number # optional
  #   # default_table_expiration_ms = number # optional
  # }))
}

variable "tables" {
  description = "Tables"
  default     = []
  type        = list
  # type = list(object({
  #   table_id   = string
  #   dataset_id = string
  #   labels     = map(string)
  #   schema     = string
  #   # expiration_time = number # optional
  #   # clustering = string # optional
  #   # time_partitioning = object({ # optional
  #   #   field = string
  #   #   type = string
  #   #   expiration_ms = number # optional
  #   # }
  # }))
}

variable "views" {
  description = "Views"
  default     = []
  type = list(object({
    dataset = string
    table   = string
    query   = string
  }))
}

variable "dataset_access" {
  description = "Dataset permissions"
  default     = {}
  type        = map(map(string))
}
