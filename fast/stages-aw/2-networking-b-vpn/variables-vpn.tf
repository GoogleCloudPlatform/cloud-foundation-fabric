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

variable "vpn_configs" {
  description = "Hub to spokes VPN configurations."
  type = object({
    dev = optional(object({
      asn = optional(number, 65501)
      custom_advertise = optional(object({
        all_subnets = bool
        ip_ranges   = map(string)
      }))
    }), {})
    landing = optional(object({
      asn = optional(number, 65500)
      custom_advertise = optional(object({
        all_subnets = bool
        ip_ranges   = map(string)
      }))
    }), {})
    prod = optional(object({
      asn = optional(number, 65502)
      custom_advertise = optional(object({
        all_subnets = bool
        ip_ranges   = map(string)
      }))
    }), {})
  })
  nullable = false
  default  = {}
}
