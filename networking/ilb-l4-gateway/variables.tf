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

variable "gateway_config" {
  description = "Gateway configuration."
  type = object({
    image          = string
    instance_count = number
    instance_type  = string
  })
  default = {
    # image        = "projects/cisco-public/global/csr1000v1721r-byol"
    image          = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2004-lts"
    instance_count = 2
    instance_type  = "f1-micro"
  }
}

variable "ip_ranges" {
  description = "IP CIDR ranges used for VPC subnets."
  type        = map(string)
  default = {
    hub     = "10.0.0.0/24"
    hub-vip = "10.0.1.0/24"
    landing = "172.16.0.0/24"
    onprem  = "10.0.16.0/24"
    tunnels = "192.168.0.0/24"
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
