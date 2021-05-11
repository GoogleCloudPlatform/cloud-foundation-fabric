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
#                    Orchestration and Transformation                         #
###############################################################################
variable "transformation_project_id" {
  description = "Orchestration and Transformation project ID."
  type        = string
}

variable "transformation_service_account" {
  description = "transformation service accounts list."
  type        = string
  default     = "sa-transformation"
}

variable "transformation_vpc_name" {
  description = "Name of the VPC created in the transformation Project."
  type        = string
  default     = "transformation-vpc"
}

variable "transformation_subnets" {
  description = "List of subnets to create in the transformation Project."
  type        = list(any)
  default = [
    {
      name               = "transformation-subnet",
      ip_cidr_range      = "10.1.0.0/20",
      secondary_ip_range = {},
      region             = "europe-west3"
    },
  ]
}

variable "transformation_buckets" {
  description = "List of transformation buckets to create"
  type        = map(any)
  default = {
    temp = {
      name     = "temp"
      location = "EU"
    },
    templates = {
      name     = "templates"
      location = "EU"
    },
  }
}
