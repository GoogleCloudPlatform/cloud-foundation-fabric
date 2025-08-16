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

variable "notification_channels" {
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
      for k, v in var.notification_channels : contains([
        "campfire", "email", "google_chat", "hipchat", "pagerduty",
        "pubsub", "slack", "sms", "webhook_basicauth", "webhook_tokenauth"
      ], v.type)
    ])
    error_message = "Invalid notification channel type."
  }
}
