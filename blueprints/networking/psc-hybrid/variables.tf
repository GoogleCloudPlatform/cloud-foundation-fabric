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

variable "prefix" {
  description = "Prefix to use for resource names."
  type        = string
}

variable "project_id" {
  description = "The ID of the project where resources will be created."
  type        = string
}

variable "region" {
  description = "Region where resources will be created."
  type        = string
}

variable "zone" {
  description = "Zone where resources will be created."
  type        = string
}

variable "dest_ip_address" {
  description = "On-prem service destination IP address."
  type        = string
}

variable "dest_port" {
  description = "On-prem service destination port."
  type        = string
  default     = "80"
}

variable "producer" {
  description = "Producer configuration."
  type        = object({
    subnet_main     = string # CIDR
    subnet_proxy    = string # CIDR
    subnet_psc      = string # CIDR
    # The accepted projects and related number of allowed PSC endpoints
    accepted_limits = map(number)
  })
}

variable "subnet_consumer" {
  description = "Consumer subnet CIDR."
  type        = string
}
