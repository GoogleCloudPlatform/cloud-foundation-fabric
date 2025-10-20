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

variable "folders" {
  description = "Folders data merged with factory data."
  type = map(object({
    name   = optional(string)
    parent = optional(string)
    iam    = optional(map(list(string)), {})
    iam_bindings = optional(map(object({
      members = list(string)
      role    = string
      condition = optional(object({
        expression  = string
        title       = string
        description = optional(string)
      }))
    })), {})
    iam_bindings_additive = optional(map(object({
      member = string
      role   = string
      condition = optional(object({
        expression  = string
        title       = string
        description = optional(string)
      }))
    })), {})
    iam_by_principals = optional(map(list(string)), {})
    pam_entitlements = optional(map(object({
      max_request_duration = string
      eligible_users       = list(string)
      privileged_access = list(object({
        role      = string
        condition = optional(string)
      }))
      requester_justification_config = optional(object({
        not_mandatory = optional(bool, true)
        unstructured  = optional(bool, false)
      }), { not_mandatory = false, unstructured = true })
      manual_approvals = optional(object({
        require_approver_justification = bool
        steps = list(object({
          approvers                = list(string)
          approvals_needed         = optional(number, 1)
          aprover_email_recipients = optional(list(string))
        }))
      }))
      additional_notification_targets = optional(object({
        admin_email_recipients     = optional(list(string))
        requester_email_recipients = optional(list(string))
      }))
    })), {})
    tag_bindings = optional(map(string), {})
  }))
  nullable = false
  default  = {}
}
