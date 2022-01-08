/**
 * Copyright 2022 Google LLC
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

variable "environment" {
  description = "Environment abbreviation used in names and labels."
  type        = string
}

variable "labels" {
  description = "Per-resource labels."
  type        = map(map(map(string)))
  default     = {}
}

variable "prefix" {
  description = "Optional name prefix."
  type        = string
  default     = null
}

variable "resources" {
  description = "Short resource names by type."
  type        = map(list(string))
}

variable "separator_override" {
  description = "Optional separator override for specific resource types."
  type        = map(string)
  default     = {}
}

variable "suffix" {
  description = "Optional name suffix."
  type        = string
  default     = null
}

variable "team" {
  description = "Team name."
  type        = string
}

variable "use_resource_prefixes" {
  description = "Prefix names with the resource type."
  type        = bool
  default     = false
}
