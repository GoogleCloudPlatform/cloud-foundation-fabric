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

variable "secops_content_config" {
  description = "Path to SecOps rules and reference lists deployment YAML config files."
  type = object({
    reference_lists = string
    rules           = string
  })
  default = {
    reference_lists = "secops_reference_lists.yaml"
    rules           = "secops_rules.yaml"
  }
}

variable "secops_tenant_config" {
  description = "SecOps tenant configuration."
  type = object({
    location = optional(string, "eu")
    instance = string
    project  = string
  })
}
