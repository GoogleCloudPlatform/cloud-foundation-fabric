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

variable "scc_sha_custom_modules" {
  description = "SCC custom modules keyed by module name."
  type = map(object({
    description    = optional(string)
    severity       = string
    recommendation = string
    predicate = object({
      expression = string
    })
    resource_selector = object({
      resource_types = list(string)
    })
    enablement_state = optional(string, "ENABLED")
  }))
  default  = {}
  nullable = false
}
