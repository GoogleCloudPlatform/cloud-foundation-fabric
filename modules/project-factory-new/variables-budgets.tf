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

variable "budgets" {
  description = "Budgets data merged with factory data."
  type = map(object({
    amount = object({
      currency_code   = optional(string)
      nanos           = optional(number)
      units           = optional(number)
      use_last_period = optional(bool)
    })
    display_name = optional(string)
    filter = optional(object({
      credit_types_treatment = optional(object({
        exclude_all       = optional(bool)
        include_specified = optional(list(string))
      }))
      label = optional(object({
        key   = string
        value = string
      }))
      period = optional(object({
        calendar = optional(string)
        custom = optional(object({
          start_date = object({
            day   = number
            month = number
            year  = number
          })
          end_date = optional(object({
            day   = number
            month = number
            year  = number
          }))
        }))
      }))
      projects           = optional(list(string))
      resource_ancestors = optional(list(string))
      services           = optional(list(string))
      subaccounts        = optional(list(string))
    }))
    threshold_rules = optional(list(object({
      percent          = number
      forecasted_spend = optional(bool)
    })), [])
    update_rules = optional(map(object({
      disable_default_iam_recipients   = optional(bool)
      monitoring_notification_channels = optional(list(string))
      pubsub_topic                     = optional(string)
    })), {})
  }))
  nullable = false
  default  = {}
}
