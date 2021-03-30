/**
 * Copyright 2021 Google LLC
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

variable "bucket_config" {
  description = "Enable and configure auto-created bucket. Set fields to null to use defaults."
  type = object({
    location             = string
    lifecycle_delete_age = number
  })
  default = null
}

variable "bucket_name" {
  description = "Name of the bucket that will be used for the function code. It will be created with prefix prepended if bucket_config is not null."
  type        = string
}

variable "bundle_config" {
  description = "Cloud function source folder and generated zip bundle paths. Output path defaults to '/tmp/bundle.zip' if null."
  type = object({
    source_dir  = string
    output_path = string
  })
}

variable "environment_variables" {
  description = "Cloud function environment variables."
  type        = map(string)
  default     = {}
}

variable "function_config" {
  description = "Cloud function configuration."
  type = object({
    entry_point      = string
    ingress_settings = string
    instances        = number
    memory           = number
    runtime          = string
    timeout          = number
  })
  default = {
    entry_point      = "main"
    ingress_settings = null
    instances        = 1
    memory           = 256
    runtime          = "python37"
    timeout          = 180
  }
}

variable "iam" {
  description = "IAM bindings for topic in {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
}

variable "ingress_settings" {
  description = "Control traffic that reaches the cloud function. Allowed values are ALLOW_ALL and ALLOW_INTERNAL_ONLY."
  type        = string
  default     = null
}

variable "labels" {
  description = "Resource labels"
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "Name used for cloud function and associated resources."
  type        = string
}

variable "prefix" {
  description = "Optional prefix used for resource names."
  type        = string
  default     = null
}

variable "project_id" {
  description = "Project id used for all resources."
  type        = string
}

variable "region" {
  description = "Region used for all resources."
  type        = string
  default     = "europe-west1"
}

variable "service_account" {
  description = "Service account email. Unused if service account is auto-created."
  type        = string
  default     = null
}

variable "service_account_create" {
  description = "Auto-create service account."
  type        = bool
  default     = false
}

variable "trigger_config" {
  description = "Function trigger configuration. Leave null for HTTP trigger."
  type = object({
    event    = string
    resource = string
    retry    = bool
  })
  default = null
}

variable "vpc_connector_config" {
  description = "VPC connector configuration. Set `create_config` attributes to trigger creation."
  type = object({
    egress_settings = string
    name            = string
    create_config = object({
      ip_cidr_range = string
      network       = string
    })
  })
  default = null
}
