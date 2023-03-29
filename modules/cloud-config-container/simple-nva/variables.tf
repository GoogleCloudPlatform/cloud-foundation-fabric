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

variable "cloud_config" {
  description = "Cloud config template path. If null default will be used."
  type        = string
  default     = null
}

variable "enable_health_checks" {
  description = "Configures routing to enable responses to health check probes."
  type        = bool
  default     = false
}

variable "files" {
  description = "Map of extra files to create on the instance, path as key. Owner and permissions will use defaults if null."
  type = map(object({
    content     = string
    owner       = string
    permissions = string
  }))
  default = {}
}

variable "frr_config" {
  description = "FRR configuration for container running on the NVA."
  type = object({
    config_file     = string
    daemons_enabled = optional(list(string))
  })
  default = null
  validation {
    condition = try(alltrue([
      for daemon in var.frr_config.daemons_enabled : contains([
        "zebra",
        "bgpd",
        "ospfd",
        "ospf6d",
        "ripd",
        "ripngd",
        "isisd",
        "pimd",
        "ldpd",
        "nhrpd",
        "eigrpd",
        "babeld",
        "sharpd",
        "staticd",
        "pbrd",
        "bfdd",
        "fabricd"
      ], daemon)
    ]), true)
    error_message = <<EOF
    Invalid entry specified in daemons_enabled list, must be one of [zebra, bgpd, ospfd, ospf6d,
    ripd, ripngd, isisd, pimd, ldpd, nhrpd, eigrpd, babeld, sharpd, staticd, pbrd, bfdd, fabricd]
    EOF
  }
}

variable "network_interfaces" {
  description = "Network interfaces configuration."
  type = list(object({
    routes              = optional(list(string))
    enable_masquerading = optional(bool, false)
    non_masq_cidrs      = optional(list(string))
  }))
}

variable "open_ports" {
  description = "Optional firewall ports to open."
  type = object({
    tcp = list(string)
    udp = list(string)
  })
  default = {
    tcp = []
    udp = []
  }
}

variable "run_cmds" {
  description = "Optional cloud init run commands to execute."
  type        = list(string)
  default     = []
}
