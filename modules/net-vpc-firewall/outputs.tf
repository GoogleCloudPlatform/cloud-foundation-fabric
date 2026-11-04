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

# The deprecated enable_logging attribute is left out of the rule resources, as
# Terraform warns when a deprecated value reaches a root module output.

locals {
  _default_rules = {
    admin = google_compute_firewall.allow_admins
    http  = google_compute_firewall.allow_tag_http
    https = google_compute_firewall.allow_tag_https
    ssh   = google_compute_firewall.allow_tag_ssh
  }
}

output "default_rules" {
  description = "Default rule resources."
  value = {
    for k, rules in local._default_rules : k => [
      for rule in rules : {
        for attr, value in rule : attr => value if attr != "enable_logging"
      }
    ]
  }
}

output "rules" {
  description = "Custom rule resources."
  value = {
    for k, rule in google_compute_firewall.custom_rules : k => {
      for attr, value in rule : attr => value if attr != "enable_logging"
    }
  }
}
