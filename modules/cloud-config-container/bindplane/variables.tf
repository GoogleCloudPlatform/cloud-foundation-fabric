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

variable "bindplane_config" {
  description = "Bindplane configurations."
  type = object({
    remote_url                      = optional(string, "localhost")
    bindplane_server_image          = optional(string, "us-central1-docker.pkg.dev/observiq-containers/bindplane/bindplane-ee:latest")
    bindplane_transform_agent_image = optional(string, "us-central1-docker.pkg.dev/observiq-containers/bindplane/bindplane-transform-agent:latest")
    bindplane_prometheus_image      = optional(string, "us-central1-docker.pkg.dev/observiq-containers/bindplane/bindplane-prometheus:1.56.0")
  })
  default  = {}
  nullable = false
}

variable "cloud_config" {
  description = "Cloud config template path. If null default will be used."
  type        = string
  default     = null
}

variable "config_variables" {
  description = "Additional variables used to render the cloud-config and Nginx templates."
  type        = map(any)
  default     = {}
}

variable "file_defaults" {
  description = "Default owner and permissions for files."
  type = object({
    owner       = string
    permissions = string
  })
  default = {
    owner       = "root"
    permissions = "0644"
  }
}

variable "files" {
  description = "Map of extra files to create on the instance, path as key. Owner and permissions will use defaults if null."
  type = map(object({
    content     = string
    owner       = string
    permissions = string
  }))
  default = {}
}

variable "password" {
  description = "Default admin user password."
  type        = string
}

variable "runcmd_post" {
  description = "Extra commands to run after starting nginx."
  type        = list(string)
  default     = []
}

variable "runcmd_pre" {
  description = "Extra commands to run before starting nginx."
  type        = list(string)
  default     = []
}

variable "users" {
  description = "List of additional usernames to be created."
  type = list(object({
    username = string,
    uid      = number,
  }))
  default = [
  ]
}
