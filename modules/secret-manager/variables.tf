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

variable "encryption_key" {
  description = "Self link of the KMS keys in {LOCATION => KEY} format. A key must be provided for all replica locations. {GLOBAL => KEY} format enables CMEK for automatic managed secrets."
  type        = map(string)
  default     = null
}

variable "iam" {
  description = "IAM bindings in {SECRET => {ROLE => [MEMBERS]}} format."
  type        = map(map(list(string)))
  default     = {}
}

variable "labels" {
  description = "Optional labels for each secret."
  type        = map(map(string))
  default     = {}
}

variable "project_id" {
  description = "Project id where the keyring will be created."
  type        = string
}

variable "secrets" {
  description = "Map of secrets to manage and their locations. If locations is null, automatic management will be set."
  type        = map(list(string))
  default     = {}
}

variable "versions" {
  description = "Optional versions to manage for each secret. Version names are only used internally to track individual versions."
  type = map(map(object({
    enabled = bool
    data    = string
  })))
  default = {}
}