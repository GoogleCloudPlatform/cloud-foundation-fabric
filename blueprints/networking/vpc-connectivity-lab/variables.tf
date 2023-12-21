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

variable "ip_ranges" {
  description = "Subnet/Routes IP CIDR ranges."
  type        = map(string)
  default = {
    ext         = "10.255.0.0/16"
    hub-a       = "10.0.1.0/24"
    hub-all     = "10.0.0.0/16"
    hub-b       = "10.0.2.0/24"
    hub-nva     = "10.0.0.0/24"
    int         = "10.0.0.0/9"
    peering-a   = "10.3.0.0/24"
    peering-b   = "10.4.0.0/24"
    rfc1918_10  = "10.0.0.0/8"
    rfc1918_172 = "172.16.0.0/12"
    rfc1918_192 = "192.168.0.0/16"
    vpn-a       = "10.1.0.0/24"
    vpn-b       = "10.2.0.0/24"
  }
}

variable "prefix" {
  description = "Prefix used for resource names."
  type        = string
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty."
  }
}

variable "project_create_config" {
  description = "Populate with billing account id to trigger project creation."
  type = object({
    billing_account_id = string
    parent_id          = string
  })
  default = null
}

variable "project_id" {
  description = "Project id for all resources."
  type        = string
  default     = "net-test-02"
}

variable "region" {
  description = "Region used to deploy resources."
  type        = string
  default     = "europe-west8"
}

variable "test_vms" {
  description = "Enable the creation of test resources."
  type        = bool
  default     = true
}

