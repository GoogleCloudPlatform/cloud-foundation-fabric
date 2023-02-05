# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

variable "location" {
  description = "The location where resources will be deployed."
  type        = string
  default     = "europe"
}

variable "prefix" {
  description = "Optional prefix used to generate resources names."
  type        = string
  nullable    = false
}

variable "project_create" {
  description = "Provide values if project creation is needed, uses existing project if null. Parent is in 'folders/nnn' or 'organizations/nnn' format."
  type = object({
    billing_account_id = string
    parent             = string
  })
  default = null
}

variable "project_ids" {
  description = "Project ids, references existing project if `project_create` is null."
  type = object({
    encryption = string
    service    = string
  })
}

variable "region" {
  description = "The region where resources will be deployed."
  type        = string
  default     = "europe-west1"
}

variable "vpc_ip_cidr_range" {
  description = "Ip range used in the subnet deployef in the Service Project."
  type        = string
  default     = "10.0.0.0/20"
}

variable "vpc_name" {
  description = "Name of the VPC created in the Service Project."
  type        = string
  default     = "local"
}

variable "vpc_subnet_name" {
  description = "Name of the subnet created in the Service Project."
  type        = string
  default     = "subnet"
}
