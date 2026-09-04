# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

output "fingerprint" {
  description = "Fingerprint of the security policy."
  value       = google_compute_security_policy.default.fingerprint
}

output "id" {
  description = "The security policy ID."
  value       = google_compute_security_policy.default.id
}

output "name" {
  description = "The security policy name."
  value       = google_compute_security_policy.default.name
}

output "security_policy" {
  description = "The security policy resource."
  value       = google_compute_security_policy.default
}

output "self_link" {
  description = "The URI of the created security policy."
  value       = google_compute_security_policy.default.self_link
}
