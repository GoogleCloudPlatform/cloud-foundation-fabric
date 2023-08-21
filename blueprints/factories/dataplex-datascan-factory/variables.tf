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

variable "datascan_defaults_file_path" {
  description = "File containing default values for the datascan configurations that can be overridden at the file level."
  type        = string
  default     = null
}

variable "merge_labels_with_defaults" {
  description = "If true, merge the default labels with the provided datascan labels. If false, the provided datascan labels will override the default labels."
  type        = bool
  default     = false
}

variable "merge_iam_bindings_defaults" {
  description = "If true, merge the default iam_bindings with the provided datascan iam_bindings. If false, the provided datascan iam_bindings will override the default iam_bindings."
  type        = bool
  default     = false
}

variable "datascan_rule_templates_file_path" {
  description = "Relative path for the YAML file containing the rule templates that can be referenced in datascans."
  type        = string
  default     = null
}

variable "datascan_spec_folder" {
  description = "Relative path for the folder containing datascan YAML configuration files."
  type        = string
}

variable "project_id" {
  description = "Default value for the project ID where the DataScans will be created. Cannot be overriden at the file level."
  type        = string
}

variable "region" {
  description = "Default value for the region where the DataScans will be created. Cannot be overriden at the file level."
  type        = string
}