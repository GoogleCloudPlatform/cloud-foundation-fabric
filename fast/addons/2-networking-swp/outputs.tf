/**
 * Copyright 2025 Google LLC
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

output "gateways" {
  description = "The gateway resources."
  value       = { for k, v in module.swp : k => v.gateway }
}

output "gateway_security_policies" {
  description = "The gateway security policy resources."
  value       = { for k, v in module.swp : k => v.gateway_security_policy }
}

output "ids" {
  description = "Gateway IDs."
  value       = { for k, v in module.swp : k => v.id }
}

output "service_attachments" {
  description = "Service attachment IDs."
  value       = { for k, v in module.swp : k => v.service_attachment }
}
