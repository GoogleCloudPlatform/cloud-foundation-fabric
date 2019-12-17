/**
 * Copyright 2018 Google LLC
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

variable "iam_members" {
  description = "IAM members keyed by key name and role."
  type        = map(map(list(string)))
  default     = {}
}

variable "iam_roles" {
  description = "IAM roles keyed by key name."
  type        = map(list(string))
  default     = {}
}

variable "keyring" {
  description = "Keyring name."
  type        = string
}

variable "key_attributes" {
  description = "Optional key attributes per key."
  type = map(object({
    protected       = bool
    rotation_period = string
  }))
  default = {}
}

variable "key_defaults" {
  description = "Key attribute defaults."
  type = object({
    protected       = bool
    rotation_period = string
  })
  default = {
    protected       = true
    rotation_period = "100000s"
  }
}

variable "keys" {
  description = "Key names."
  type        = list(string)
  default     = []
}

# cf https://cloud.google.com/kms/docs/locations
variable "location" {
  description = "Location for the keyring."
  type        = string
}

variable "project_id" {
  description = "Project id where the keyring will be created."
  type        = string
}
