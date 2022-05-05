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

output "admin_ranges" {
  description = "Admin ranges data."

  value = {
    enabled = length(var.admin_ranges) > 0
    ranges  = join(",", var.admin_ranges)
  }
}

output "custom_egress_allow_rules" {
  description = "Custom egress rules with allow blocks."
  value = [
    for rule in google_compute_firewall.custom-rules :
    rule.name if rule.direction == "EGRESS" && try(length(rule.allow), 0) > 0
  ]
}

output "custom_egress_deny_rules" {
  description = "Custom egress rules with allow blocks."
  value = [
    for rule in google_compute_firewall.custom-rules :
    rule.name if rule.direction == "EGRESS" && try(length(rule.deny), 0) > 0
  ]
}

output "custom_ingress_allow_rules" {
  description = "Custom ingress rules with allow blocks."
  value = [
    for rule in google_compute_firewall.custom-rules :
    rule.name if rule.direction == "INGRESS" && try(length(rule.allow), 0) > 0
  ]
}

output "custom_ingress_deny_rules" {
  description = "Custom ingress rules with deny blocks."
  value = [
    for rule in google_compute_firewall.custom-rules :
    rule.name if rule.direction == "INGRESS" && try(length(rule.deny), 0) > 0
  ]
}

output "rules" {
  description = "All google_compute_firewall resources created."
  value = merge(
    google_compute_firewall.custom-rules,
    try({ (google_compute_firewall.allow-admins.0.name) = google_compute_firewall.allow-admins.0 }, {}),
    try({ (google_compute_firewall.allow-tag-ssh.0.name) = google_compute_firewall.allow-tag-ssh.0 }, {}),
    try({ (google_compute_firewall.allow-tag-http.0.name) = google_compute_firewall.allow-tag-http.0 }, {}),
    try({ (google_compute_firewall.allow-tag-https.0.name) = google_compute_firewall.allow-tag-https.0 }, {})
  )
}
