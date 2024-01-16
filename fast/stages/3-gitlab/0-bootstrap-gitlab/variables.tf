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

variable "billing_account" {
  # tfdoc:variable:source 0-bootstrap
  description = "Billing account id. If billing account is not part of the same org set `is_org_level` to `false`. To disable handling of billing IAM roles set `no_iam` to `true`."
  type = object({
    id           = string
    is_org_level = optional(bool, true)
    no_iam       = optional(bool, false)
  })
  nullable = false
}

variable "gitlab_access_token" {
  description = "Personal Access Token for programmatic access to Gitlab instance."
  type = string
}

variable "gitlab_hostname" {
  description = "Gitlab hostname"
}

variable "gitlab_runner_vm_config" {
  description = "Gitlab Runner VM configuration."
  type        = object({
    instance_type = optional(string, "n2-standard-2")
    name          = optional(string, "gitlab-runner")
    network_tags  = optional(list(string), [])
    private_ip    = optional(string, null)
    public_ip     = optional(bool, false)
  })
  nullable = false
  default  = {}
}

variable "host_project_ids" {
  type = object({
    dev-spoke-0 = string
  })
}

variable "prefix" {
  type = string
}

variable "region" {
  type    = string
  default = "europe-west8"
}

variable "root_node" {
  type = string
}

variable "subnet_name" {
  type = string
}

variable "subnet_self_links" {
  type = object({
    dev-spoke-0 = map(string)
  })
}

variable "vpc_self_links" {
  type = object({
    dev-spoke-0 = string
  })
}

variable "project_id" {
  description = "GCP project id."
  type        = string
}

variable "project_create" {
  description = "Create project instead of using an existing one."
  type        = bool
  default     = false
}