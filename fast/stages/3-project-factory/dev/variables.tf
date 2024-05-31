/**
 * Copyright 2024 Google LLC
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

variable "factories_config" {
  description = "Path to folder with YAML resource description data files."
  type = object({
    hierarchy = optional(object({
      folders_data_path = string
      parent_ids        = optional(map(string), {})
    }))
    projects_data_path = string
    budgets = optional(object({
      billing_account       = string
      budgets_data_path     = string
      notification_channels = optional(map(any), {})
    }))
  })
  nullable = false
}
