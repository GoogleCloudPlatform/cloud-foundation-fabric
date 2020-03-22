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

variable "bucket_name" {
  description = "Name of the bucket that will be used for the function code, leave null to create one."
  type        = string
  default     = null
}

variable "bundle_config" {
  description = "Cloud function code bundle configuration, output path is a zip file."
  type = object({
    source_dir  = string
    output_path = string
  })
}

variable "function_config" {
  description = "Cloud function configuration."
  type = object({
    entry_point = string
    instances   = number
    memory      = number
    runtime     = string
    timeout     = number
  })
  default = {
    entry_point = "main"
    instances   = 1
    memory      = 256
    runtime     = "python37"
    timeout     = 180
  }
}

variable "name" {
  description = "Name used for resources (schedule, topic, etc.)."
  type        = string
}

variable "prefixes" {
  description = "Optional prefixes for resource ids, null prefixes will be ignored."
  type = object({
    bucket          = string
    function        = string
    job             = string
    service_account = string
    topic           = string
  })
  default = null
}

variable "project_id" {
  description = "Project id used for all resources."
  type        = string
}

variable "region" {
  description = "Region used for all resources."
  type        = string
  default     = "us-central1"
}

variable "schedule_config" {
  description = "Cloud function scheduler job configuration, leave data null to pass the name variable, set schedule to null to disable schedule."
  type = object({
    pubsub_data = string
    schedule    = string
    time_zone   = string
  })
  default = {
    schedule    = "*/10 * * * *"
    pubsub_data = null
    time_zone   = "UTC"
  }
}

variable "service_account_iam_roles" {
  description = "IAM roles assigned to the service account at the project level."
  type        = list(string)
  default     = []
}

# variable "source_repository_url" {
#   type    = string
#   default = ""
# }
