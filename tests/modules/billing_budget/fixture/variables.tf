/**
 * Copyright 2022 Google LLC
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

variable "amount" {
  type    = number
  default = 0
}

variable "credit_treatment" {
  type    = string
  default = "INCLUDE_ALL_CREDITS"
}

variable "email_recipients" {
  type = object({
    project_id = string
    emails     = list(string)
  })
  default = null
}

variable "notification_channels" {
  type    = list(string)
  default = null
}

variable "notify_default_recipients" {
  type    = bool
  default = false
}

variable "projects" {
  type    = list(string)
  default = null
}

variable "pubsub_topic" {
  type    = string
  default = null
}

variable "services" {
  type    = list(string)
  default = null
}

variable "thresholds" {
  type = object({
    current    = list(number)
    forecasted = list(number)
  })
  default = {
    current    = [0.5, 1.0]
    forecasted = [1.0]
  }
}
