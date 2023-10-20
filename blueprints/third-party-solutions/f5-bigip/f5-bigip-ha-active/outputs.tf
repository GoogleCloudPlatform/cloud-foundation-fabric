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

output "f5_management_ips" {
  description = "The F5 management interfaces IP addresses."
  value = {
    for k, v in module.bigip-vms
    : v.id => v.internal_ips[1]
  }
}

output "forwarding_rules_config" {
  description = "The GCP forwarding rules configurations."
  value = {
    external = {
      for _, v in try(module.passthrough-nlb[0].forwarding_rules, {})
      : v.name => {
        address    = v.ip_address
        ip_version = v.ip_version
        protocol   = v.ip_protocol
      }
    },
    internal = {
      for _, v in try(module.passthrough-ilb[0].forwarding_rules, {})
      : v.name => {
        address       = v.ip_address
        global_access = v.allow_global_access
        ip_version    = v.ip_version
        protocol      = v.ip_protocol
      }
    }
  }
}
