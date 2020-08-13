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

variable "ilb_right_enable" {
  description = "Route right to left traffic through ILB."
  type        = bool
  default     = false
}

variable "ilb_session_affinity" {
  description = "Session affinity configuration for ILBs."
  type        = string
  default     = "CLIENT_IP"
}

variable "ip_ranges" {
  description = "IP CIDR ranges used for VPC subnets."
  type        = map(string)
  default = {
    left  = "10.0.0.0/24"
    right = "10.0.1.0/24"
  }
}

variable "prefix" {
  description = "Prefix used for resource names."
  type        = string
  default     = "ilb-test"
}

variable "project_id" {
  description = "Existing project id."
  type        = string
}

variable "public_key_path" {
  description = "Path to the public key used for the admin user on the gateways. If null a key pair will be generated."
  type        = string
}

variable "region" {
  description = "Region used for resources."
  type        = string
  default     = "europe-west1"
}
