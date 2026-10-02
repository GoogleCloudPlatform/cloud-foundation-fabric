/**
 * Copyright 2026 Google LLC
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

output "addresses" {
  description = "Load balancer addresses."
  value = {
    external = module.ralb.address
    internal = module.ilb.address
  }
}

output "commands" {
  description = "Commands to exercise the security policy."
  value = {
    external-request = "curl -si http://${module.ralb.address}/"
    external-sqli    = "curl -si 'http://${module.ralb.address}/?id=1%20OR%201=1'"
    internal-sqli    = "curl -si 'http://${module.ilb.address}/?id=1%20OR%201=1' # from a VM in the VPC"
  }
}

output "security_policy" {
  description = "Security policy id."
  value       = module.waf.id
}
