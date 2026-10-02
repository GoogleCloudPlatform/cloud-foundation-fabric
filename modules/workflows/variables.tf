# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

variable "call_log_level" {
  description = "Describes the level of platform logging to apply to calls and call responses during executions of this workflow."
  type        = string
  default     = null
  validation {
    condition = (
      var.call_log_level == null ||
      contains(
        ["LOG_ALL_CALLS", "LOG_ERRORS_ONLY", "LOG_NONE"],
        var.call_log_level
      )
    )
    error_message = "call_log_level must be one of LOG_ALL_CALLS, LOG_ERRORS_ONLY, or LOG_NONE."
  }
}

variable "context" {
  description = "Context-specific interpolations."
  type = object({
    kms_keys         = optional(map(string), {})
    locations        = optional(map(string), {})
    project_ids      = optional(map(string), {})
    pubsub_topics    = optional(map(string), {})
    service_accounts = optional(map(string), {})
  })
  nullable = false
  default  = {}
}

variable "crypto_key_name" {
  description = "The KMS key name used to encrypt workflow data at rest."
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Whether deletion protection is enabled for this workflow."
  type        = bool
  default     = false
}

variable "description" {
  description = "Description of the workflow."
  type        = string
  default     = null
}

variable "env_vars" {
  description = "User-defined environment variables associated with this workflow revision."
  type        = map(string)
  default     = {}
}

variable "eventarc_triggers" {
  description = "Eventarc triggers that invoke this workflow. Map keys are trigger names."
  type = map(object({
    location                = optional(string)
    service_account         = optional(string)
    labels                  = optional(map(string), {})
    event_data_content_type = optional(string)
    matching_criteria = optional(list(object({
      attribute = string
      value     = string
      operator  = optional(string)
    })), [])
    pubsub_topic = optional(string)
    retry_policy = optional(object({
      max_attempts = optional(number)
    }))
  }))
  default  = {}
  nullable = false
}

variable "execution_history_level" {
  description = "Describes the level of execution history to apply to executions of this workflow."
  type        = string
  default     = null
  validation {
    condition = (
      var.execution_history_level == null ||
      contains(
        [
          "EXECUTION_HISTORY_BASIC",
          "EXECUTION_HISTORY_DETAILED"
        ],
        var.execution_history_level
      )
    )
    error_message = "execution_history_level must be one of EXECUTION_HISTORY_BASIC or EXECUTION_HISTORY_DETAILED."
  }
}

variable "labels" {
  description = "A set of key/value label pairs to assign to this Workflow."
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "Name of the Workflow."
  type        = string
}

variable "prefix" {
  description = "Optional prefix used for resource names."
  type        = string
  default     = null
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty, please use null instead."
  }
}

variable "project_id" {
  description = "The ID of the project in which the resource belongs."
  type        = string
}

variable "region" {
  description = "The region of the workflow."
  type        = string
}

variable "scheduler_jobs" {
  description = "Cloud Scheduler jobs to trigger this workflow. Map keys are job names."
  type = map(object({
    schedule         = string
    time_zone        = optional(string, "Etc/UTC")
    description      = optional(string)
    paused           = optional(bool, false)
    attempt_deadline = optional(string)
    argument         = optional(string)
    call_log_level   = optional(string)
    headers          = optional(map(string), {})
    region           = optional(string)
    service_account  = optional(string)
    uri              = optional(string)
    oauth_token = optional(object({
      service_account_email = string
      scope = optional(
        string, "https://www.googleapis.com/auth/cloud-platform"
      )
    }))
    oidc_token = optional(object({
      service_account_email = string
      audience              = optional(string)
    }))
    retry_config = optional(object({
      retry_count          = optional(number)
      max_retry_duration   = optional(string)
      min_backoff_duration = optional(string)
      max_backoff_duration = optional(string)
      max_doublings        = optional(number)
    }))
  }))
  default  = {}
  nullable = false
}

variable "service_account" {
  description = "Service account configuration. If create is true, a dedicated service account is created and granted roles on the workflow's project (project_id)."
  type = object({
    create       = optional(bool, false)
    display_name = optional(string)
    email        = optional(string)
    name         = optional(string)
    roles        = optional(list(string), [])
  })
  default = null
}

variable "source_contents" {
  description = "Workflow code to be executed (YAML or JSON string)."
  type        = string
  default     = <<-EOT
    main:
      params: [args]
      steps:
        - step1:
            return: OK
  EOT
}

variable "tags" {
  description = "Resource management tags."
  type        = map(string)
  default     = null
}

variable "task_queues" {
  description = "Cloud Tasks queues to create for this workflow. Map keys are queue names."
  type = map(object({
    location        = optional(string)
    deletion_policy = optional(string)
    rate_limits = optional(object({
      max_concurrent_dispatches = optional(number)
      max_dispatches_per_second = optional(number)
    }))
    retry_config = optional(object({
      max_attempts       = optional(number)
      max_backoff        = optional(string)
      max_doublings      = optional(number)
      max_retry_duration = optional(string)
      min_backoff        = optional(string)
    }))
    stackdriver_logging_config = optional(object({
      sampling_ratio = number
    }))
    http_target = optional(object({
      http_method      = optional(string)
      header_overrides = optional(map(string), {})
      oauth_token = optional(object({
        service_account_email = string
        scope                 = optional(string)
      }))
      oidc_token = optional(object({
        service_account_email = string
        audience              = optional(string)
      }))
      uri_override = optional(object({
        host                      = optional(string)
        port                      = optional(string)
        scheme                    = optional(string)
        uri_override_enforce_mode = optional(string)
        path                      = optional(string)
        query_params              = optional(string)
      }))
    }))
  }))
  default  = {}
  nullable = false
}
