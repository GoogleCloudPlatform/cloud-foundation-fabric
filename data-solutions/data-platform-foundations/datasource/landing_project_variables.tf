/**
 * Copyright 2020 Google LLC
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

###############################################################################
#                                 landing                                     #
###############################################################################
variable "landing_buckets" {
  description = "List of landing buckets to create"
  type        = map(any)
  default = {
    raw-data = {
      name     = "raw-data"
      location = "EU"
    },
    data-schema = {
      name     = "data-schema"
      location = "EU"
    },
  }
}

variable "landing_project_id" {
  description = "landing project ID."
  type        = string
}

variable "landing_pubsub" {
  description = "List of landing buckets to create"
  type        = map(any)
  default = {
    landing_1 = {
      name = "landing-1"
      subscriptions = {
        sub1 = {
          labels = {},
          options = {
            ack_deadline_seconds       = null
            message_retention_duration = null
            retain_acked_messages      = false
            expiration_policy_ttl      = null
          }
        },
        sub2 = {
          labels = {},
          options = {
            ack_deadline_seconds       = null
            message_retention_duration = null
            retain_acked_messages      = false
            expiration_policy_ttl      = null
          }
        },
      }
      subscription_iam = {
        sub1 = {
          "roles/pubsub.subscriber" = []
        }
        sub2 = {
          "roles/pubsub.subscriber" = []
        }
      }
    }
  }
}

variable "landing_service_account" {
  description = "landing service accounts list."
  type        = string
  default     = "sa-landing"
}
