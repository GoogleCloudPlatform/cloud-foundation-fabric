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

variable "iam" {
  description = "IAM bindings for topic in {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "iam_bindings" {
  description = "Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary."
  type = map(object({
    members = list(string)
    role    = string
    condition = optional(object({
      expression  = string
      title       = string
      description = optional(string)
    }))
  }))
  nullable = false
  default  = {}
}

variable "iam_bindings_additive" {
  description = "Keyring individual additive IAM bindings. Keys are arbitrary."
  type = map(object({
    member = string
    role   = string
    condition = optional(object({
      expression  = string
      title       = string
      description = optional(string)
    }))
  }))
  nullable = false
  default  = {}
}

variable "kms_key" {
  description = "KMS customer managed encryption key."
  type        = string
  default     = null
}

variable "labels" {
  description = "Labels."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "message_retention_duration" {
  description = "Minimum duration to retain a message after it is published to the topic."
  type        = string
  default     = null
}

variable "name" {
  description = "PubSub topic name."
  type        = string
}

variable "project_id" {
  description = "Project used for resources."
  type        = string
}

variable "regions" {
  description = "List of regions used to set persistence policy."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "schema" {
  description = "Topic schema. If set, all messages in this topic should follow this schema."
  type = object({
    definition   = string
    msg_encoding = optional(string, "ENCODING_UNSPECIFIED")
    schema_type  = string
  })
  default = null
}

variable "subscriptions" {
  description = "Topic subscriptions. Also define push configs for push subscriptions. If options is set to null subscription defaults will be used. Labels default to topic labels if set to null."
  type = map(object({
    labels                       = optional(map(string))
    ack_deadline_seconds         = optional(number)
    message_retention_duration   = optional(string)
    retain_acked_messages        = optional(bool, false)
    expiration_policy_ttl        = optional(string)
    filter                       = optional(string)
    enable_message_ordering      = optional(bool, false)
    enable_exactly_once_delivery = optional(bool, false)
    dead_letter_policy = optional(object({
      topic                 = string
      max_delivery_attempts = optional(number)
    }))
    retry_policy = optional(object({
      minimum_backoff = optional(number)
      maximum_backoff = optional(number)
    }))

    bigquery = optional(object({
      table               = string
      use_topic_schema    = optional(bool, false)
      write_metadata      = optional(bool, false)
      drop_unknown_fields = optional(bool, false)
    }))
    cloud_storage = optional(object({
      bucket          = string
      filename_prefix = optional(string)
      filename_suffix = optional(string)
      max_duration    = optional(string)
      max_bytes       = optional(number)
      avro_config = optional(object({
        write_metadata = optional(bool, false)
      }))
    }))
    push = optional(object({
      endpoint   = string
      attributes = optional(map(string))
      no_wrapper = optional(bool, false)
      oidc_token = optional(object({
        audience              = optional(string)
        service_account_email = string
      }))
    }))

    iam = optional(map(list(string)), {})
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
  }))
  default  = {}
  nullable = false
}
