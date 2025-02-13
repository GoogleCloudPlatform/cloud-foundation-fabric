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

variable "backend_vm_configs" {
  description = "The sample backend VMs configuration. Keys are the zones where VMs are deployed."
  type = map(object({
    address        = string
    instance_type  = string
    startup_script = string
  }))
  default = {
    a = {
      address        = "192.168.100.101"
      instance_type  = "e2-micro"
      startup_script = "apt update && apt install -y nginx"
    }
    b = {
      address        = "192.168.100.102"
      instance_type  = "e2-micro"
      startup_script = "apt update && apt install -y nginx"
    }
  }
}

variable "forwarding_rules_config" {
  type = map(object({
    address       = optional(string)
    external      = optional(bool, false)
    global_access = optional(bool, true)
    ipv6          = optional(bool, false)
    protocol      = optional(string, "L3_DEFAULT")
    subnetwork    = optional(string) # used for IPv6 NLBs
  }))
  description = "The optional configurations of the GCP load balancers forwarding rules."
  default = {
    "ipv4" = {
      address  = "192.168.100.100"
      protocol = "TCP"
    }
    "ipv6" = {
      ipv6 = true
    }
  }
}

variable "instance_dedicated_configs" {
  description = "The F5 VMs configuration. The map keys are the zones where the VMs are deployed."
  type        = map(any)
  default = {
    a = {
      license_key = "AAAAA-BBBBB-CCCCC-DDDDD-EEEEEEE"
      network_config = {
        alias_ip_range_address = "192.168.101.0/24"
        alias_ip_range_name    = "f5-a"
      }
    }
    b = {
      license_key = "AAAAA-BBBBB-CCCCC-DDDDD-EEEEEEE"
      network_config = {
        alias_ip_range_address = "192.168.102.0/24"
        alias_ip_range_name    = "f5-b"
      }
    }
  }
}

variable "instance_shared_config" {
  description = "The F5 VMs shared configurations."
  type        = map(any)
  default = {
    enable_ipv6    = true
    ssh_public_key = "./data/mykey.pub"
  }
}

variable "prefix" {
  type        = string
  description = "The name prefix used for resources."
}

variable "project_create" {
  description = "Whether to automatically create a project."
  type        = bool
  default     = false
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
  description = "VPC and subnet ids, in case existing VPCs are used."
  type = object({
    backend_vms_cidr = string # used by F5s. Not configured on the VPC.
    dataplane = object({
      subnets = map(object({
        cidr                = optional(string)
        secondary_ip_ranges = optional(map(string)) # name -> cidr
      }))
    })
    management = object({
      subnets = map(object({
        cidr                = optional(string)
        secondary_ip_ranges = optional(map(string)) # name -> cidr
      }))
    })
  })
  default = {
    backend_vms_cidr = "192.168.200.0/24"
    dataplane = {
      subnets = {
        clients = {
          cidr = "192.168.0.0/24"
        }
        dataplane = {
          cidr = "192.168.100.0/24"
          secondary_ip_ranges = {
            f5-a = "192.168.101.0/24"
            f5-b = "192.168.102.0/24"
          }
        }
      }
    }
    management = {
      subnets = {
        management = {
          cidr = "192.168.250.0/24"
        }
      }
    }
  }
}
