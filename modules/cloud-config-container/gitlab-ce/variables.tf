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

variable "cloud_config" {
  description = "Cloud-config template path. If null default will be used."
  type        = string
  default     = null
}

variable "config_variables" {
  description = "Additional template variables passed to the cloud-config template."
  type        = map(any)
  default     = {}
}

variable "env" {
  description = "Environment variables for the gitlab-ce container."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "env_file" {
  description = "Environment variables file for the gitlab-ce container."
  type        = string
  default     = null
}

variable "hostname" {
  description = "Hostname passed to the gitlab-ce container."
  type        = string
  default     = null
}

variable "image" {
  description = "Gitlab-ce container image."
  type        = string
  default     = "gitlab/gitlab-ce:latest"
}

variable "mounts" {
  description = "Disk device names and paths in the disk filesystem for the gitlab-ce container paths."
  type = object({
    config = object({
      device_name = string
      fs_path     = string
    })
    data = object({
      device_name = string
      fs_path     = string
    })
    logs = object({
      device_name = string
      fs_path     = string
    })
  })
  default = {
    config = { device_name = "data", fs_path = "config" }
    data   = { device_name = "data", fs_path = "data" }
    logs   = { device_name = "data", fs_path = "logs" }
  }
  nullable = false
}
