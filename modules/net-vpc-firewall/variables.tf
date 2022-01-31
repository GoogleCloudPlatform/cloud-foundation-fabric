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

variable "admin_ranges" {
  description = "IP CIDR ranges that have complete access to all subnets."
  type        = list(string)
  default     = []
}

variable "cidr_template_file" {
  description = "Path for optional file containing name->cidr_list map to be used by the rules factory."
  type        = string
  default     = null
}

variable "custom_rules" {
  description = "List of custom rule definitions (refer to variables file for syntax)."
  type = map(object({
    description          = string
    direction            = string
    action               = string # (allow|deny)
    ranges               = list(string)
    sources              = list(string)
    targets              = list(string)
    use_service_accounts = bool
    rules = list(object({
      protocol = string
      ports    = list(string)
    }))
    extra_attributes = map(string)
  }))
  default = {}
}

variable "data_folder" {
  description = "Path for optional folder containing firewall rules defined as YaML objects used by the rules factory."
  type        = string
  default     = null
}

variable "http_source_ranges" {
  description = "List of IP CIDR ranges for tag-based HTTP rule, defaults to the health checkers ranges."
  type        = list(string)
  default     = ["35.191.0.0/16", "130.211.0.0/22", "209.85.152.0/22", "209.85.204.0/22"]
}

variable "https_source_ranges" {
  description = "List of IP CIDR ranges for tag-based HTTPS rule, defaults to the health checkers ranges."
  type        = list(string)
  default     = ["35.191.0.0/16", "130.211.0.0/22", "209.85.152.0/22", "209.85.204.0/22"]
}

variable "named_ranges" {
  description = "Names that can be used of valid values for the `ranges` field of `custom_rules`."
  type        = map(list(string))
  default = {
    any                   = ["0.0.0.0/0"]
    dns-forwarders        = ["35.199.192.0/19"]
    health-checkers       = ["35.191.0.0/16", "130.211.0.0/22", "209.85.152.0/22", "209.85.204.0/22"]
    iap-forwarders        = ["35.235.240.0/20"]
    private-googleapis    = ["199.36.153.8/30"]
    restricted-googleapis = ["199.36.153.4/30"]
    rfc1918               = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }
}

variable "network" {
  description = "Name of the network this set of firewall rules applies to."
  type        = string
}

variable "project_id" {
  description = "Project id of the project that holds the network."
  type        = string
}

variable "ssh_source_ranges" {
  description = "List of IP CIDR ranges for tag-based SSH rule, defaults to the IAP forwarders range."
  type        = list(string)
  default     = ["35.235.240.0/20"]
}

