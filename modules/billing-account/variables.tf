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

variable "budget_notification_channels" {
  description = "Notification channels used by budget alerts."
  type = map(object({
    project_id   = string
    type         = string
    description  = optional(string)
    display_name = optional(string)
    enabled      = optional(bool, true)
    force_delete = optional(bool)
    labels       = optional(map(string))
    sensitive_labels = optional(list(object({
      auth_token  = optional(string)
      password    = optional(string)
      service_key = optional(string)
    })))
    user_labels = optional(map(string))
  }))
  nullable = false
  default  = {}
  validation {
    condition = alltrue([
      for k, v in var.budget_notification_channels : contains([
        "campfire", "email", "google_chat", "hipchat", "pagerduty",
        "pubsub", "slack", "sms", "webhook_basicauth", "webhook_tokenauth"
      ], v.type)
    ])
    error_message = "Invalid notification channel type."
  }
}

variable "budgets" {
  description = "Billing budgets. Notification channels are either keys in corresponding variable, or external ids."
  type = map(object({
    amount = object({
      currency_code   = optional(string)
      nanos           = optional(number)
      units           = optional(number)
      use_last_period = optional(bool)
    })
    display_name    = optional(string)
    ownership_scope = optional(string)
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
  validation {
    condition = alltrue([
      for k, v in var.budgets : v.amount != null && (
        try(v.amount.use_last_period, null) == true ||
        try(v.amount.units, null) != null
      )
    ])
    error_message = "Each budget needs to have amount units specified, or use last period."
  }
  validation {
    condition = alltrue(flatten([
      for k, v in var.budgets : [
        for kk, vv in v.update_rules : [
          vv.monitoring_notification_channels != null
          ||
          vv.pubsub_topic != null
        ]
      ]
    ]))
    error_message = "Budget notification rules need either a pubsub topic or monitoring channels defined."
  }
}

variable "factories_config" {
  description = "Path to folder containing budget alerts data files."
  type = object({
    budgets_data_path = optional(string, "data/billing-budgets")
  })
  nullable = false
  default  = {}
}

variable "id" {
  description = "Billing account id."
  type        = string
}

variable "logging_sinks" {
  description = "Logging sinks to create for the billing account."
  type = map(object({
    destination          = string
    type                 = string
    bq_partitioned_table = optional(bool, false)
    description          = optional(string)
    disabled             = optional(bool, false)
    exclusions = optional(map(object({
      filter      = string
      description = optional(string)
      disabled    = optional(bool)
    })), {})
    filter = optional(string)
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.logging_sinks :
      contains(["bigquery", "logging", "project", "pubsub", "storage"], v.type)
    ])
    error_message = "Type must be one of 'bigquery', 'logging', 'project', 'pubsub', 'storage'."
  }
  validation {
    condition = alltrue([
      for k, v in var.logging_sinks :
      v.bq_partitioned_table != true || v.type == "bigquery"
    ])
    error_message = "Can only set bq_partitioned_table when type is `bigquery`."
  }
}

variable "projects" {
  description = "Projects associated with this billing account."
  type        = list(string)
  nullable    = false
  default     = []
}
