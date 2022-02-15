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

variable "f_bootstrap" {
  description = "Data coming from the boostrap stage"
  type = object({
    automation_project_id = string
    billing_account = object({
      id              = string
      organization_id = number
    })
    custom_roles = map(string)
    groups       = map(string)
    organization = object({
      domain      = string
      id          = number
      customer_id = string
    })
    prefix = string
  })
}

variable "f_resman" {
  description = "Data coming from the resman stage"
  type = object({
    folder_ids = map(string)
    automation_resources = map(object({
      gcs = string
      sa  = string
    }))
  })
}

variable "f_networking" {
  description = "Data coming from the networking stage"
  type = object({
    shared_vpcs       = map(string)
    vpc_host_projects = map(string)
    dns_zones         = map(string)
  })
}
