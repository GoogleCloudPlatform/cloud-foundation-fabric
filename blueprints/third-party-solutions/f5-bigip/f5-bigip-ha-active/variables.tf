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

variable "f5_vms_dedicated_config" {
  description = "The F5 VMs configuration. The map keys are the zones where the VMs are deployed."
  type = map(object({
    network_config = object({
      alias_ip_range_address = string
      alias_ip_range_name    = string
      dataplane_address      = optional(string)
      management_address     = optional(string)
    })
    license_key = optional(string, "AAAAA-BBBBB-CCCCC-DDDDD-EEEEEEE")
  }))
}

variable "f5_vms_shared_config" {
  description = "The F5 VMs shared configurations."
  type = object({
    disk_size       = optional(number, 100)
    enable_ipv6     = optional(bool, false) # needs to be true to receive traffic from IPv6 forwarding rules
    image           = optional(string, "projects/f5-7626-networks-public/global/images/f5-bigip-15-1-2-1-0-0-10-byol-ltm-2boot-loc-210115160742")
    instance_type   = optional(string, "n2-standard-4")
    secret          = optional(string, "mysecret")
    service_account = optional(string)
    ssh_public_key  = optional(string, "my_key.pub")
    tags            = optional(list(string), [])
    use_gcp_secret  = optional(bool, false)
    username        = optional(string, "admin")
  })
  default = {}
}

variable "forwarding_rules_config" {
  type = map(object({
    address       = optional(string)
    external      = optional(bool, false)
    global_access = optional(bool, true)
    ip_version    = optional(string, "IPV4")
    protocol      = optional(string, "L3_DEFAULT")
    subnetwork    = optional(string) # used for IPv6 NLBs
  }))
  description = "The optional configurations of the GCP load balancers forwarding rules."
  default = {
    l4 = {}
  }
}

variable "health_check_config" {
  description = "The optional health check configuration."
  type        = map(any)
  default = {
    tcp = {
      port               = 65535
      port_specification = "USE_FIXED_PORT"
    }
  }
}

variable "prefix" {
  type        = string
  description = "The name prefix used for resources."
}

variable "project_id" {
  type        = string
  description = "The project id where we deploy the resources."
}

variable "region" {
  type        = string
  description = "The region where we deploy the F5 IPs."
}

variable "vpc_config" {
  description = "The dataplane and mgmt network and subnetwork self links."
  type = object({
    dataplane = object({
      network    = string
      subnetwork = string
    })
    management = object({
      network    = string
      subnetwork = string
    })
  })
}
