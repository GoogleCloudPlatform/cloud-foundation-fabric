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

variable "pam_entitlements" {
  description = "Privileged Access Manager entitlements for this resource, keyed by entitlement ID."
  type = map(object({
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
        approvers                 = list(string)
        approvals_needed          = optional(number, 1)
        approver_email_recipients = optional(list(string))
      }))
    }))
    additional_notification_targets = optional(object({
      admin_email_recipients     = optional(list(string))
      requester_email_recipients = optional(list(string))
    }))
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for v in values(var.pam_entitlements) :
      !v.requester_justification_config.not_mandatory || !v.requester_justification_config.unstructured
    ])
    error_message = "Only one of 'not_mandatory' or 'unstructured' can be enabled in 'requester_justification_config'."
  }
}
