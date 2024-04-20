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

variable "quotas" {
  description = "Service quota configuration."
  type = map(object({
    service              = string
    quota_id             = string
    preferred_value      = number
    dimensions           = optional(map(string), {})
    justification        = optional(string)
    contact_email        = optional(string)
    annotations          = optional(map(string))
    ignore_safety_checks = optional(string)
  }))
  nullable = false
  default  = {}
  validation {
    condition = alltrue([
      for k, v in var.quotas :
      v.ignore_safety_checks == null || contains(
        [
          "QUOTA_DECREASE_BELOW_USAGE",
          "QUOTA_DECREASE_PERCENTAGE_TOO_HIGH",
          "QUOTA_SAFETY_CHECK_UNSPECIFIED"
        ],
        coalesce(v.ignore_safety_checks, "-")
    )])
    error_message = "Invalid value for ignore safety checks."
  }
}
